
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CollectionQuiz", function () {
    let CollectionQuiz;
    let collectionQuiz;
    let owner, addr2;
    let quizArr;

    this.beforeEach(async () => {
        [owner, addr2] = await ethers.getSigners();
        CollectionQuiz = await ethers.getContractFactory("CollectionQuiz");
        collectionQuiz = await CollectionQuiz.deploy();
    });

    it("Thêm Quiz với chủ hợp đồng", async () => {
        const location = "cau";
        const URI = "URI1";
        let correct = 1;
        // Kiểm tra trước khi tạo quiz
        const initialQuizCount = await collectionQuiz.getQuizLength();
        // Lấy ra số lượng câu hỏi thuộc location
        const locationCount = await collectionQuiz.getLocationCount(location);
        // Tạo một quiz mới
        await collectionQuiz.connect(owner).createQuiz(location, URI, correct); 
        // So sánh số lượng quiz
        // Mảng sau khi thêm các Quiz
        expect(await collectionQuiz.getQuizLength()).to.be.above(Number(initialQuizCount));
        expect(await collectionQuiz.getLocationCount(location)).to.be.above(locationCount);      
        
    });

    it('Nếu null', async ()=>{
        await expect(
             collectionQuiz.connect(owner).createQuiz('y', '', 0)
          ).to.be.revertedWith("Values cannot be empty and _correct must be non-zero");

          await expect(
            collectionQuiz.connect(owner).createQuiz("HN30", "URI", 1)
          ).to.not.be.reverted;
    })

    it("Chỉ chủ hợp đồng mới có thể thêm mới quiz", async () => {
        console.log(owner.getAddress())
        console.log(addr2.getAddress())


    });


    it("Cập Nhật Quiz", async () => {
        const location = "cau";
        const URI = "URI1";
        let correct = 1;
        const _id = 1;

        // + Tạo một quiz mới để update
        await collectionQuiz.connect(owner).createQuiz(location, URI, correct);
      

        // Danh sách khi thêm xong
        //console.log(await collectionQuiz.getQuizs())
        // + Kiểm tra updateQuiz
        await collectionQuiz.connect(owner).updateQuiz(_id, "Cau hoi cap nhap", "Uri", 5)
        // Danh sách sau khi cập nhật
        //console.log(await collectionQuiz.getQuizs());

        // + Kiểm tra kết quả trả về cửa sự kiện
        const events = await collectionQuiz.queryFilter("updatedNewQuiz");
        const eventArgs = events[0].args;
        // So sánh giá trị nhập vào với giá trị từ sự kiện
        expect(eventArgs._location).to.equal("Cau hoi cap nhap");
        expect(eventArgs._URI).to.equal("Uri");
        expect(Number(eventArgs._correct)).to.equal(Number(5));
        expect(Number(eventArgs._id)).to.equal(Number(_id));
    })

    it("Chỉ người chủ sở hữu mới có có quyền sửa", async () => {
        await collectionQuiz.connect(owner).createQuiz("Câu hỏi 1", "Uri thêm 1", 1);
        // Nếu không phải là người tạo quiz thì không thể nào update
        await expect(
            collectionQuiz.connect(addr2).updateQuiz(1, "Cau hỏi sau khi update", "URI upadare", 2)
        ).to.be.revertedWith("Caller is not owner");
    })

    it("Id cập nhật ngoài vùng bộ nhớ", async () => {
        await collectionQuiz.connect(owner).createQuiz("Câu hỏi 1", "Uri thêm 1", 1);
        // Nếu không phải là người tạo quiz thì không thể nào update
        await expect(
            collectionQuiz.connect(owner).updateQuiz(3, "Cau hỏi 1", "URi 1", 4)
        ).to.be.revertedWith("ID does not exist");
    })

    // Lấy ra 1 mảng câu đố

    it("Lấy danh sách câu hỏi cho một Mã và số lượng câu", async () => {
        for (let i = 0; i <= 15; i++) {
            correct = i;
            await collectionQuiz.connect(owner).createQuiz("HN29", "url" + i, 1);
           // quizArr = await collectionQuiz.getQuizs();
        }
        const location = "HN29";
        const amount = 10;
        const quizzes = await collectionQuiz.getArrayQuizForLocation(location, amount);

        console.log(quizzes)
        // Kiểm tra xem danh sách có đúng số lượng câu hỏi bạn muốn lấy không
        expect(await quizzes.length).to.equal(amount);
        // Kiểm tra xem các câu hỏi đã được xáo trộn (danh sách không phải lúc nào cũng theo thứ tự tạo)
        const firstQuiz = quizzes[0];
        console.log(firstQuiz);
        const count = await collectionQuiz.getLocationCount("HN29")
        console.log(count)
    })


    it("Kiểm tra số lượng câu hỏi cần lấy ra có lớn hơn số lượng câu hỏi theo location", async () => {
        for (let i = 0; i <= 15; i++) {
            correct = i;
            await collectionQuiz.connect(owner).createQuiz("HN29", "url" + i, 1);
            
        }
        const location = "HN29";
        const amount = 50;
        // const quizzes = await collectionQuiz.getArrayQuizForLocation(location, amount );
        await expect(
            collectionQuiz.getArrayQuizForLocation(location, amount)
        ).to.be.rejectedWith("Not enough questions");
    })
});
