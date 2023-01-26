require("dotenv").config();
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const Web3 = require('web3');
var web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_QUICKNODE_GOERLI_URL))
// const Moralis = require("moralis").default;
const ABI = require("./abi.json");

exports.mintToCustomer = functions
    .runWith({
        enforceAppCheck: true  // Requests without valid App Check tokens will be rejected.
    })
    .https.onCall(async (data, _) => {
        if (context.app == undefined) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'The function must be called from an App Check verified app.')
        }

        web3.eth.accounts.wallet.add(process.env.ETH_PRIVATE_KEY);
        var proxyUZSO = new web3.eth.Contract(ABI, process.env.UZSO_PROXY_ADDRESS, {
            // from: process.env.ETH_PUBLIC_KEY, // default from address
            // gasPrice: '20000000000' // default gas price in wei, 20 gwei in this case
        });

        proxyUZSO.methods.mintToCustomer(web3.utils.toChecksumAddress(data.to), data.amount).estimateGas({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address) })
            .then(function (gasAmount) {
                if (gasAmount <= 30000000000) {
                    proxyUZSO.methods.mintToCustomer(web3.utils.toChecksumAddress(data.to), data.amount).send({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address), gas: gasAmount })
                        .on('confirmation', function (confirmationNumber, receipt) {
                            console.log("CONFIRMATION");
                            console.log(confirmationNumber);
                            console.log(receipt);
                            return receipt;
                        })
                        .on('error', function (error, receipt) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
                            console.log("ERROR1");
                            console.log(error);
                            console.log(receipt);
                            return "ERROR";
                        });
                } else {
                    console.log("NOT ENOUGH GAS");
                    console.log(error);
                    return "NOT ENOUGH GAS";
                }
            })
            .catch(function (error) {
                console.log("ERROR");
                console.log(error);
            });

    });

exports.burn = functions
    .runWith({
        enforceAppCheck: true  // Requests without valid App Check tokens will be rejected.
    })
    .https.onCall(async (data, _) => {
        if (context.app == undefined) {
            throw new functions.https.HttpsError(
                'failed-precondition',
                'The function must be called from an App Check verified app.')
        }

        web3.eth.accounts.wallet.add(process.env.ETH_PRIVATE_KEY);
        var proxyUZSO = new web3.eth.Contract(ABI, process.env.UZSO_PROXY_ADDRESS, {
            // from: process.env.ETH_PUBLIC_KEY, // default from address
            // gasPrice: '20000000000' // default gas price in wei, 20 gwei in this case
        });

        proxyUZSO.methods.burn(web3.utils.toChecksumAddress(data.account), data.amount).estimateGas({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address) })
            .then(function (gasAmount) {
                if (gasAmount <= 30000000000) {
                    proxyUZSO.methods.burn(web3.utils.toChecksumAddress(data.account), data.amount).send({ from: web3.utils.toChecksumAddress(web3.eth.accounts.privateKeyToAccount(process.env.ETH_PRIVATE_KEY).address), gas: gasAmount })
                        .on('confirmation', function (confirmationNumber, receipt) {
                            console.log("CONFIRMATION");
                            console.log(confirmationNumber);
                            console.log(receipt);
                            return receipt;
                        })
                        .on('error', function (error, receipt) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
                            console.log("ERROR1");
                            console.log(error);
                            console.log(receipt);
                            return "ERROR";
                        });
                } else {
                    console.log("NOT ENOUGH GAS");
                    console.log(error);
                    return "NOT ENOUGH GAS";
                }
            })
            .catch(function (error) {
                console.log("ERROR");
                console.log(error);
            });

    });




// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
