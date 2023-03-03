require("dotenv").config();
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const Web3 = require('web3');

// const Moralis = require("moralis").default;
const ABI_UZSO_GOERLI = require("./abi_uzso_goerli.json");
const ABI_UZSO_POLYGON_MUMBAI = require("./abi_uzso_polygon_mumbai.json");

var web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_QUICKNODE_GOERLI_URL))
var ABI = ABI_UZSO_GOERLI;
var proxy_address = process.env.UZSO_GOERLI_PROXY_ADDRESS

admin.initializeApp();


exports.mintToCustomer = functions
    .runWith({
        enforceAppCheck: false  // Requests without valid App Check tokens will be rejected.
    })
    .https.onCall(async (data, context) => {
        if (context.app == undefined) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'The function must be called from an App Check verified app.')
        }


        if (data.blockchainNetwork == 'goerli') {
            web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_QUICKNODE_GOERLI_URL))
            ABI = ABI_UZSO_GOERLI;
            proxy_address = process.env.UZSO_GOERLI_PROXY_ADDRESS
        } else if (data.blockchainNetwork == 'polygon_mumbai') {
            web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_ALCHEMY_POLYGON_MUMBAI_URL))
            ABI = ABI_UZSO_POLYGON_MUMBAI;
            proxy_address = process.env.UZSO_POLYGON_MUMBAI_PROXY_ADDRESS
        } else {
            return "ERROR";
        }

        web3.eth.accounts.wallet.add(process.env.ETH_PRIVATE_KEY);
        var proxyUZSO = new web3.eth.Contract(ABI, proxy_address, {
            // from: process.env.ETH_PUBLIC_KEY, // default from address
            // gasPrice: '20000000000' // default gas price in wei, 20 gwei in this case
        });

        proxyUZSO.methods.mintToCustomer(web3.utils.toChecksumAddress(data.to), data.amount).estimateGas({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address) })
            .then(function (gasAmount) {
                if (gasAmount <= 30000000000) {
                    proxyUZSO.methods.mintToCustomer(web3.utils.toChecksumAddress(data.to), data.amount).send({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address), gas: gasAmount })
                        .on('confirmation', function (confirmationNumber, receipt) {

                            if (confirmationNumber >= 10) {
                                console.log("CONFIRMATION");
                                console.log(confirmationNumber);
                                console.log(receipt);
                                // admin.firestore().collection("payments").doc(data.paymentId).update({
                                //     "status_code": 2,
                                //     "web3Transaction": receipt,
                                // });
                                return receipt;
                            }
                        })
                        .on('error', function (error, receipt) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
                            console.log("ERROR1");
                            console.log(error);
                            console.log(receipt);
                            // admin.firestore().collection("payments").doc(data.paymentId).update({
                            //     "status_code": 3,
                            //     "web3Transaction": receipt,
                            // });
                            return "ERROR";
                        });
                } else {
                    // admin.firestore().collection("payments").doc(data.paymentId).update({
                    //     "status_code": 3,
                    //     "web3Transaction": "NOT ENOUGH GAS",
                    // });
                    console.log("NOT ENOUGH GAS");
                    console.log(error);
                    return "NOT ENOUGH GAS";
                }
            })
            .catch(function (error) {
                // admin.firestore().collection("payments").doc(data.paymentId).update({
                //     "status_code": 3,
                //     "web3Transaction": "ERROR",
                // });
                console.log("ERROR");
                console.log(error);
                return "ERROR";
            });
    });


exports.burn = functions
    .runWith({
        enforceAppCheck: true  // Requests without valid App Check tokens will be rejected.
    })
    .https.onCall(async (data, context) => {
        if (context.app == undefined) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'The function must be called from an App Check verified app.')
        }


        if (data.blockchainNetwork == 'goerli') {
            web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_QUICKNODE_GOERLI_URL))
            ABI = ABI_UZSO_GOERLI;
            proxy_address = process.env.UZSO_GOERLI_PROXY_ADDRESS
        } else if (data.blockchainNetwork == 'polygon_mumbai') {
            web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_ALCHEMY_POLYGON_MUMBAI_URL))
            ABI = ABI_UZSO_POLYGON_MUMBAI;
            proxy_address = process.env.UZSO_POLYGON_MUMBAI_PROXY_ADDRESS
        } else {
            return "ERROR";
        }

        web3.eth.accounts.wallet.add(process.env.ETH_PRIVATE_KEY);
        var proxyUZSO = new web3.eth.Contract(ABI, proxy_address, {
            // from: process.env.ETH_PUBLIC_KEY, // default from address
            // gasPrice: '20000000000' // default gas price in wei, 20 gwei in this case
        });

        proxyUZSO.methods.burn(web3.utils.toChecksumAddress(data.account), data.amount).estimateGas({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address) })
            .then(function (gasAmount) {
                if (gasAmount <= 30000000000) {
                    proxyUZSO.methods.burn(web3.utils.toChecksumAddress(data.account), data.amount).send({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address), gas: gasAmount })
                        .on('confirmation', function (confirmationNumber, receipt) {

                            if (confirmationNumber >= 10) {
                                console.log("CONFIRMATION");
                                console.log(confirmationNumber);
                                console.log(receipt);
                                // admin.firestore().collection("payments").doc(data.paymentId).update({
                                //     "status_code": 2,
                                //     "web3Transaction": receipt,
                                // });
                                return receipt;
                            }
                        })
                        .on('error', function (error, receipt) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
                            console.log("ERROR1");
                            console.log(error);
                            console.log(receipt);
                            // admin.firestore().collection("payments").doc(data.paymentId).update({
                            //     "status_code": 3,
                            //     "web3Transaction": receipt,
                            // });
                            return "ERROR";
                        });
                } else {
                    // admin.firestore().collection("payments").doc(data.paymentId).update({
                    //     "status_code": 3,
                    //     "web3Transaction": "NOT ENOUGH GAS",
                    // });
                    console.log("NOT ENOUGH GAS");
                    console.log(error);
                    return "NOT ENOUGH GAS";
                }
            })
            .catch(function (error) {
                // admin.firestore().collection("payments").doc(data.paymentId).update({
                //     "status_code": 3,
                //     "web3Transaction": "ERROR",
                // });
                console.log("ERROR");
                console.log(error);
                return "ERROR";
            });

    });
