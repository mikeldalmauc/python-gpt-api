import jwt from 'jsonwebtoken';

const authenticateToken = (req, res, next) => {
  const token = req.session.jwt;
  if (!token) {
    return res.status(401).send('Access Denied: No Token Provided!');
  }
  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET);
    req.user = verified;
    next();
  } catch (err) {
    res.status(400).send('Invalid Token');
  }
};

export default authenticateToken;
