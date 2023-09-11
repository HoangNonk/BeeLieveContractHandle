// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CollectionQuiz {
    address private _owner;
    uint256 private quizCount = 0;
    struct Quiz {
        uint256 id;
        string location;
        string URI;
        uint256 correct;
    }

    Quiz[] private Quizs;

    // Lấy ra các thuộc tính theo ID từ 0
    function getQuizLength () public view  returns (uint ){
        return Quizs.length;
    }
    function getQuizs (uint256 _id) public view returns (Quiz memory quiz){
        return Quizs[_id];
    }
    function getLocation (uint256 _id) public view returns (string memory location ){
        return Quizs[_id].location;
    }
    function getURI (uint256 _id) public view returns (string memory uri ){
        return Quizs[_id].URI;
    }
    function getCorrect (uint256 _id) public view returns (uint256  correct ){
        return Quizs[_id].correct;
    }

    // Location : số lượng câu hỏi thuộc location
    mapping(string => uint256) locationToCountQuestion;
    
    // Số Câu Hỏi Theo location
    function getLocationCount(string memory location) public view returns (uint256) {
    return locationToCountQuestion[location];
}


    event createNewQuiz(
        uint256 _id,
        string _location,
        string _URI,
        uint256 _correct
    );

    event updatedNewQuiz(
        uint256 _id,
        string _location,
        string _URI,
        uint256 _correct
    );

// Định nghĩa một sự kiện để theo dõi khi hàm được gọi và trả về mảng Quiz
    event GetArrayQuizForLocationEvent(
        address indexed _caller,
        string _location,
        uint256 _amount,
        Quiz[] _quizzes
);
    constructor() {
        _owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    // Hàm tạo một câu hỏi mới (chỉ chủ hợp đồng mới tạo được)
    function createQuiz(
        string memory _location,
        string memory _URI,
        uint32 _correct
    ) public isOwner {
        require(bytes(_location).length > 0 
        && bytes(_URI).length > 0 
        && _correct != 0, 
        "Values cannot be empty and _correct must be non-zero");
        quizCount++;
        Quizs.push(Quiz(quizCount, _location, _URI, _correct));
        locationToCountQuestion[_location] += 1;
        emit createNewQuiz(quizCount, _location, _URI, _correct);
    }

   

    // Hàm thay đổi nội dung (URI) và đáp án đúng của câu hỏi có sẵn
    // Chỉ chủ hợp đồng mới sửa được
    function updateQuiz(
        uint256 _id,
        string memory _location,
        string memory _URI,
        uint256 _correct
    ) public isOwner {
        require(_id <= quizCount && _id > 0, "ID does not exist");

        Quiz storage quiz = Quizs[_id - 1];
        if (
            keccak256(abi.encodePacked(quiz.location)) !=
            keccak256(abi.encodePacked(_location))
        ) {
            locationToCountQuestion[quiz.location] -= 1;
            locationToCountQuestion[_location] += 1;
            quiz.location = _location;
        }
        quiz.URI = _URI;
        quiz.correct = _correct;
        emit updatedNewQuiz(_id, _location, _URI, _correct);
    }
    function getArrayQuizForLocation(string memory _location, uint256 _amount)
        public
        view
        returns (Quiz[] memory)
    {
        require(
            _amount <= locationToCountQuestion[_location],
            "Not enough questions"
        );
        uint256 length = locationToCountQuestion[_location];
        uint256[] memory idInLocation = new uint256[](length);
        uint256 count = 0;
        for (uint256 i = 0; i < Quizs.length; i++) {
            Quiz memory quiz = Quizs[i];
            if (
                keccak256(abi.encodePacked(quiz.location)) ==
                keccak256(abi.encodePacked(_location))
            ) {
                idInLocation[count] = quiz.id;
                count++;
            }
        }

        // xáo trộn mảng
        for (uint256 i = length - 1; i > 0; i--) {
            uint256 j = uint256(
                keccak256(abi.encodePacked(block.timestamp, i))
            ) % (i + 1);
            (idInLocation[i], idInLocation[j]) = (
                idInLocation[j],
                idInLocation[i]
            );
        }
        Quiz[] memory result = new Quiz[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
            result[i] = Quizs[idInLocation[i]-1];
        }
        return result;
    }

    function getAndEmitArrayQuizForLocation(string memory _location, uint256 _amount) public  {
        Quiz[] memory result = getArrayQuizForLocation(_location, _amount);
        emit GetArrayQuizForLocationEvent(_owner, _location, _amount, result);
    }

    function getAll() public view returns (Quiz[] memory) {
        return Quizs;
    }
}