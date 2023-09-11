// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    Web3 Game  - BEELIEVE 
    FPT Polytechnic Hà Nội
    Teams:      + Nguyễn Vĩnh Long
                + Lương Hoàng Long
                + Vũ Ngọc Tú
                + Nguyễn Tiến Mạnh
                + Quang Phúc
*/

contract CollectionBeelieve {
    address private _owner;

    struct Piece {
        uint256 id;
        uint256 types;
        uint256 index;
        string imgUrl;
        string picture;
        address ownerId;
        bool isActive;
    }

    Piece[] private Pieces;

    // Mapping id : Piece
    // Tất cả các Piece có trong game
    mapping(uint256 => Piece) public allPiece;

    // Mapping string : id
    // Lưu id các Piece lớn bằng tên bức tranh (picture)
    mapping(string => uint256) public PieceSpecial;

    // Mapping address : count
    // Lưu trữ số lượng Piece sở hữu bởi địa chỉ ví
    mapping(address => uint256) public ownerByAddressCount;

    // Mapping id : forSale
    // Lưu trữ trạng thái bán của id
    mapping(uint256 => bool) public idForSale;

    // Mapping id : price
    // Lưu trữ giá bán theo id
    mapping(uint256 => uint256) public idForPrice;

    constructor() {
        _owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    event creatNewPiece(
        uint256 _id,
        uint256 _types,
        uint256 _index,
        string _mgUrl,
        string _picture,
        address _ownerId,
        bool _isActive
    );

    event exchangePiece(
        uint256 _id,
        address seller,
        address buyer,
        uint256 price
    );

    event upgradeNFTBigEvent(string _picture, address _address);
    event sellPieceEvent(uint256 _id, uint256 _price);
    event giveRandomPieceEvent(
        uint256 _id,
        uint256 _index,
        string _imgUrl,
        string _picture
    );

    // Hàm tạo Piece dành cho chủ hợp đồng
    function createPiece(
        uint256 _types,
        string memory _imgUrl,
        string memory _picture,
        uint256 _index
    ) public isOwner {
        uint256 _id = Pieces.length + 1;
        Piece memory newPiece = Piece(
            _id,
            _types,
            _index,
            _imgUrl,
            _picture,
            _owner,
            true
        );
        Pieces.push(newPiece);
        allPiece[_id] = Pieces[_id - 1];
        idForSale[_id] = false;
        if (_types == 1) PieceSpecial[_picture] = _id;
        ownerByAddressCount[msg.sender] += 1;
        emit creatNewPiece(
            _id,
            _types,
            _index,
            _imgUrl,
            _picture,
            _owner,
            true
        );
    }

    // Hàm lấy tất cả các mảnh ghép một Address sở hữu
    function getAllPieceByAddress(
        address _address
    ) public view returns (Piece[] memory) {
        Piece[] memory list = new Piece[](ownerByAddressCount[_address]);

        uint256 count = 0;

        for (uint256 i = 0; i < Pieces.length; i++) {
            Piece memory p = Pieces[i];
            if (p.ownerId == _address) {
                list[count] = p;
                count++;
            }
        }

        return list;
    }

    // Hàm đổi 8 mảnh ghép nhỏ lấy về 1 bức tranh lớn
    // Sau khi đổi 8 mảnh ghép sẽ được vô hiệu hóa và chuyển về cho chủ hợp đồng
    function upgradeNFTBig(string memory _picture, address _address) public {
        require(
            keccak256(abi.encodePacked(msg.sender)) ==
                keccak256(abi.encodePacked(_address)),
            "User was able to upgrade with equal 10 NFTs"
        );

        Piece[] memory list = getAllPieceByAddress(_address);
        Piece[] memory listLock = new Piece[](10);
        uint256 count = 0;

        for (uint256 i = 0; i < list.length; i++) {
            Piece memory p = list[i];
            if (
                keccak256(abi.encodePacked(p.picture)) ==
                keccak256(abi.encodePacked(_picture)) &&
                p.types != 1
            ) {
                listLock[count] = list[i];
                count++;
                if (count == 8) break;
            }
        }

        require(count == 8, "User was able to upgrade with equal 8 NFTs");

        for (uint256 i = 0; i < count; i++) {
            uint256 id = listLock[i].id;
            Piece storage p = Pieces[id - 1];
            p.isActive = false;
            if (p.ownerId != _owner) p.ownerId = _owner;
            allPiece[id] = p;
        }

        Piece storage special = Pieces[PieceSpecial[_picture] - 1];
        uint256 specialId = special.id;
        special.ownerId = _address;
        allPiece[specialId] = special;

        ownerByAddressCount[_owner] += 7;
        ownerByAddressCount[_address] -= 7;

        emit upgradeNFTBigEvent(_picture, _address);
    }

    // Hàm đăng bán Piece
    function sellPiece(uint256 _id, uint256 _price) public {
        require(Pieces[_id - 1].ownerId == msg.sender, "Owner only sell");
        idForSale[_id] = true;
        if (idForPrice[_id] != _price) idForPrice[_id] = _price;
        emit sellPieceEvent(_id, _price);
    }

    //Hàm mua Piece
    function buyPiece(uint256 _id) public payable {
        require(idForSale[_id], "Not already for buy");
        address payable seller = payable(Pieces[_id - 1].ownerId);
        require(seller != msg.sender, "Can't buy your own");
        uint256 price = idForPrice[_id] * 10 ** 18;
        require(msg.value >= price, "Not enough money");

        idForSale[_id] = false;
        Pieces[_id - 1].ownerId = msg.sender;
        allPiece[_id] = Pieces[_id - 1];
        seller.transfer(price);

        ownerByAddressCount[msg.sender] += 1;
        ownerByAddressCount[seller] -= 1;

        emit exchangePiece(_id, seller, msg.sender, price);
    }

    // Hàm rơi ngẫu nhiên mảnh cho người chơi
    function giveRandomPiece() public {
        require(ownerByAddressCount[_owner] > 0, "No more spare shards");
        uint256[] memory validIndices = new uint256[](
            ownerByAddressCount[_owner]
        );

        uint256 validCount = 0;

        for (uint256 i = 0; i < Pieces.length; i++) {
            Piece memory p = Pieces[i];
            if (p.ownerId == _owner && p.types == 0 && p.isActive == true) {
                validIndices[validCount] = i;
                validCount++;
            }
        }

        require(validCount > 0, "Not enough valid pieces");

        // Xáo trộn mảng
        for (uint256 i = validCount - 1; i > 0; i--) {
            uint256 j = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        blockhash(block.number - 1)
                    )
                )
            ) % (i + 1);
            uint256 temp = validIndices[i];
            validIndices[i] = validIndices[j];
            validIndices[j] = temp;
        }

        // Chọn phần tử đầu tiên sau khi trộn mảng
        uint256 selectedPieceIndex = validIndices[0];
        Piece storage selectedPiece = Pieces[selectedPieceIndex];
        uint256 selectedId = selectedPiece.id;
        selectedPiece.ownerId = msg.sender;
        allPiece[selectedId] = selectedPiece;
        ownerByAddressCount[msg.sender] += 1;
        ownerByAddressCount[_owner] -= 1;

        emit giveRandomPieceEvent(
            selectedPiece.id,
            selectedPiece.index,
            selectedPiece.imgUrl,
            selectedPiece.picture
        );
    }

    // Hàm lấy tất cả các Piece đang được đăng bán
    function getAllPieceForSale()
        public
        view
        returns (Piece[] memory, uint256[] memory _price)
    {
        // Duyệt mảng lớn đếm xem có bao nhiêu Piece đang trong trạng thái bán
        uint256 count = 0;
        for (uint256 i = 0; i < Pieces.length; i++) {
            if (idForSale[i + 1]) {
                count++;
            }
        }

        Piece[] memory pieceForSale = new Piece[](count);
        uint256[] memory priceForSale = new uint256[](count);

        //Lấy thông tin về Piece đang được đăng bán và giá tương ứng
        uint256 index = 0;
        for (uint256 i = 0; i < Pieces.length; i++) {
            if (idForSale[i + 1]) {
                pieceForSale[index] = Pieces[i];
                priceForSale[index] = idForPrice[i + 1];
                index++;
            }
        }

        return (pieceForSale, priceForSale);
    }

    // Tổng số Piece trong game
    function all() public view returns (uint256) {
        return Pieces.length;
    }
}