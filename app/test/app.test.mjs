// File: test/app.test.mjs
import chai from 'chai';
import chaiHttp from 'chai-http';
import { app as server } from '../app.mjs'; // Ensure your main app file is also renamed to `.mjs`
import redisClient from '../middlewares/redisClient.mjs';
import { initializeUser } from '../utils/userInit.mjs';
const expect = chai.expect;

chai.use(chaiHttp);

describe('User Authentication', () => {
    before(async () => {
        await initializeUser('test@example.com', 'testpass', 'user');
    });

    after(() => {
        redisClient.del('test@example.com');
    });

    it('should login with valid credentials', (done) => {
        chai.request(server)
            .post('/auth/login')
            .send({ email: 'test@example.com', password: 'testpass' })
            .end((err, res) => {
                expect(res).to.have.status(200);
                expect(res.body).to.have.property('token');
                done();
            });
    });

    it('should fail login with invalid credentials', (done) => {
        chai.request(server)
            .post('/auth/login')
            .send({ email: 'test@example.com', password: 'wrongpass' })
            .end((err, res) => {
                expect(res).to.have.status(401);
                expect(res.body).to.have.property('message').eql('Invalid email or password');
                done();
            });
    });

    it('should fail login with non-existing user', (done) => {
        chai.request(server)
            .post('/auth/login')
            .send({ email: 'nonexist@example.com', password: 'nopass' })
            .end((err, res) => {
                expect(res).to.have.status(401);
                expect(res.body).to.have.property('message').eql('Invalid email or password');
                done();
            });
    });
});