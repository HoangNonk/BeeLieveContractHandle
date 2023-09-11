// const {
//   loadFixture,
// } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
//const Web3 = require("@nomiclabs/hardhat-web3-legacy");
// const web3 = new Web3(provider);

// const truffleAssert = require('truffle-assertions');

describe("CollectionBeelieve", function () {
  let owner; // tài khoản
  let user1; // tài khoản
  let user2; // tài khoản
  let collection; // hợp đồng

  
  before(async function () {
    [owner, user1, user2] = await ethers.getSigners(); // lấy tài khoản tự tạo

    const CollectionBeelieveFactory = await ethers.getContractFactory("CollectionBeelieve");
    collection = await CollectionBeelieveFactory.deploy();
    await collection.deployed;

    // Tạo 8 mảnh nhỏ thuộc một bức tranh HN30
    for (let i = 0; i < 8; i++) {
      await collection.connect(owner).createPiece(0, "HN30-" + i, "HN30", "" + i);
    }
    console.log(await collection.connect(owner).getAllPieceByAddress(owner.address));
  });


  it("Lấy tất cả các mảnh của 1 address - 10 piece", async function () {
    // Tất cả là 8 bức tranh
    expect(await collection.connect(owner).ownerByAddressCount(owner.address)).to.equal(8);
  });


  //Kiểm tra không cho phép người không phải là owner tạo một Piece:
  it("Không cho phép người dùng tạo bức tranh", async function () {
    await expect(
      collection.connect(user2).createPiece(0, "image-url", "picture-1", 1)).to.be.revertedWith("Caller is not owner");
  });

  it("User1 random nhận Piece từ Owner (10 lần)", async function () {
    // User 1 random 10 lần nhận về 10 mảnh
    for (let i = 0; i < 8; i++) {
      await collection.connect(user1).giveRandomPiece();
    }
    expect(await collection.connect(user1).ownerByAddressCount(user1.address)).to.equal(8);
    expect(await collection.connect(owner).ownerByAddressCount(owner.address)).to.equal(0);
  });

  // Tạo một mảnh lớn cho bức tranh HN30 - Bức tranh lớn này là ID:9
  it("Tạo một mảnh lớn cho bức tranh HN30", async function () {
    const initialPieceCount = await collection.all();
    const tx = await collection.connect(owner).createPiece(1, "HN30-10", "HN30", 8);
    const newPieceCount = await collection.all();
    // Kiểm tra sự kiện văng ra
    await expect(tx).to.emit(collection, 'creatNewPiece').withArgs(newPieceCount, 1, 8, "HN30-10", "HN30", owner.address, true);
    expect(newPieceCount - initialPieceCount).to.equal(1);
    expect(await collection.connect(owner).ownerByAddressCount(owner.address)).to.equal(1);
  });

  // Kiểm tra nâng cấp khi đủ 10 NFT:
  it("Kiểm tra sau khi đổi 8 mảnh nhỏ lấy 1 mảnh lớn", async function () {
    const ownerByUser1Before = await collection.connect(user1).ownerByAddressCount(user1.address);
    const ownerByOwnerBefore = await collection.connect(owner).ownerByAddressCount(owner.address);
    const tx = await collection.connect(user1).upgradeNFTBig("HN30", user1.address);
    const ownerByUser1After = await collection.connect(user1).ownerByAddressCount(user1.address);
    const ownerByOwnerAfter = await collection.connect(owner).ownerByAddressCount(owner.address);
    // Kiểm tra sự kiện văng ra
    await expect(tx).to.emit(collection, 'upgradeNFTBigEvent').withArgs('HN30', user1.address);
    // User1 khi đổi 8 mảnh nhỏ lấy về 1 mảnh lớn
    expect(ownerByUser1Before - ownerByUser1After).to.equal(7);
    // Owner khi nhận 8 mảnh nhỏ và gửi đi 1 mảnh lớn
    expect(ownerByOwnerAfter - ownerByOwnerBefore).to.equal(7);
  });


  // Kiểm tra nút đăng bán 
  it("Kiểm tra đăng bán một mảnh - Mảnh lớn HN30 sau khi đổi", async function () {
    // đăng bán mảnh có id = 9 với giá 30;
    const tx = await collection.connect(user1).sellPiece(9, 30);
    await tx.wait();

    // Kiểm tra sự kiện văng ra
    await expect(tx).to.emit(collection, 'sellPieceEvent').withArgs(9, 30);

    // Kiểm tra trạng thái bán và giá của id này
    const isSale = await collection.connect(user1).idForSale(9);
    expect(isSale).to.equal(true);
    const isPrice = await collection.connect(user1).idForPrice(9);
    expect(isPrice).to.equal(30);
  });

  it("Kiểm tra tất cả các mảnh đang được đăng bán", async function () {
    // Đếm xem có tất cả bao nhiêu mảnh đang được đăng bán
    let expectedCount = 0;
    let totalPiece = await collection.connect(user1).all();
    for (let i = 0; i < totalPiece; i++) {
      if (await collection.connect(user1).idForSale(i + 1)) {
        expectedCount++;
      }
    }
    // Lấy ra kết quả 2 mảng tương ứng mảnh và giá đang được bán
    const [pieceForSale, priceForSale] = await collection.getAllPieceForSale();

    // Kiểm tra xem độ dài 2 mảng lấy ra từ hàm có giống như vòng lặp đếm không
    expect(pieceForSale.length).to.equal(expectedCount);
    expect(priceForSale.length).to.equal(expectedCount);

    // Kiểm tra số lượng mảnh đang được bán có bằng số lượng trong case test không (=1)
    expect(pieceForSale.length).to.equal(1);
    expect(priceForSale.length).to.equal(1);
  });


  it("Kiểm tra hành động mua một Piece", async function () {
    const blanceBeforeUser1 = await ethers.provider.getBalance(user1.address);
    const blanceBeforeUser2 = await ethers.provider.getBalance(user2.address);
    // Cho user2 mua ID:9 đang được đăng bán bởi user1
    const price = await collection.connect(user2).idForPrice(9);
    const priceToWei = ethers.parseUnits(price.toString(), "ether");
    
    const tx = await collection.connect(user2).buyPiece(9, { value:  priceToWei.toString()});
    await expect(tx).to.emit(collection, 'exchangePiece').withArgs(9, user1.address, user2.address, priceToWei);
    const blanceAfterUser2 = await ethers.provider.getBalance(user2.address);
    const blanceAfterUser1 = await ethers.provider.getBalance(user1.address);

    // Tính toán chi phí gas dựa trên gasPrice và gasUsed của giao dịch
    const gasPrice = (await tx.wait()).gasPrice;
    const gasUsed = (await tx.wait()).gasUsed;
    const gasCost = gasPrice * gasUsed;
    
     // So sánh số dư sau trừ đi số dư trước cộng với chi phí gas
     expect(blanceBeforeUser2 - blanceAfterUser2).to.equal(priceToWei + gasCost);
     expect(blanceAfterUser1 - blanceBeforeUser1).to.equal(priceToWei);

    

  });

});