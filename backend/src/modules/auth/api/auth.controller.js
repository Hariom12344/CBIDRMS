const {
    registerUser,
    loginUser,
    logoutUser,
    refreshTokenUser,
    forgotPasswordUser,
    resetPasswordUser
} = require("../logic/auth.service");



// REGISTER

const register = async (req, res) => {

    try {

        const result = await registerUser(req.body);

        const {
            password,
            refreshToken,
            resetToken,
            resetTokenExpiry,
            ...safeUser
        } = result.user;


        res.status(201).json({

            message: "User registered successfully",

            accessToken: result.accessToken,

            refreshToken: result.refreshToken,

            user: safeUser

        });


    } catch (error) {

        res.status(400).json({

            message: error.message

        });

    }

};




// LOGIN

// LOGIN

const login = async (req, res) => {

    try {

        const result = await loginUser(req.body);


        const {
            password,
            refreshToken,
            resetToken,
            resetTokenExpiry,
            ...safeUser
        } = result.user;



        res.status(200).json({

            message: "Login successful",

            accessToken: result.accessToken,

            refreshToken: result.refreshToken,

            user: safeUser

        });


    } catch (error) {

        res.status(400).json({

            message: error.message

        });

    }

};



// LOGOUT

const logout = async (req, res) => {

    try {

        const result = await logoutUser(req.body.userId);


        res.status(200).json(result);


    } catch(error){

        res.status(400).json({

            message:error.message

        });

    }

};




// REFRESH TOKEN

const refreshToken = async (req, res) => {

    try {

        const result =
            await refreshTokenUser(
                req.body.refreshToken
            );


        res.status(200).json(result);


    } catch(error){

        res.status(400).json({

            message:error.message

        });

    }

};




// FORGOT PASSWORD

const forgotPassword = async (req, res) => {

    try {

        const result =
            await forgotPasswordUser(
                req.body.email
            );


        res.status(200).json(result);


    } catch(error){

        res.status(400).json({

            message:error.message

        });

    }

};




// RESET PASSWORD

const resetPassword = async (req, res) => {

    try {

        const result =
            await resetPasswordUser(
                req.body
            );


        res.status(200).json(result);


    } catch(error){

        res.status(400).json({

            message:error.message

        });

    }

};



module.exports = {

    register,

    login,

    logout,

    refreshToken,

    forgotPassword,

    resetPassword

};