
require("@nomicfoundation/hardhat-toolbox");
//require("@nomiclabs/hardhat-web3-legacy");
require('dotenv').config();
// require("@openzeppelin/contracts");

//accounts: [process.env.PRIV_KEY]

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.4",
  networks: {
    klaytn: {
      url: "https://public-en-baobab.klaytn.net", // Thay đổi URL tùy theo mạng bạn muốn sử dụng
      accounts: [process.env.PRIV_KEY], // Thay đổi private key của bạn
    },
  },
};
