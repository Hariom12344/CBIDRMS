const jwt = require("jsonwebtoken");


const generateAccessToken = (payload) => {

    return jwt.sign(
        payload,
        process.env.JWT_SECRET,
        {
            expiresIn: process.env.JWT_EXPIRES_IN
        }
    );

};



const generateRefreshToken = (payload) => {

    return jwt.sign(
        payload,
        process.env.REFRESH_TOKEN_SECRET,
        {
            expiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN
        }
    );

};



module.exports = {
    generateAccessToken,
    generateRefreshToken
};