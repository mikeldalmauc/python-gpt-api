const mongoose = require('mongoose');

const queryLogSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    query: { type: String, required: true },
    response: { type: String, required: true },
    queryDate: { type: Date, default: Date.now },
    responseDate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('QueryLog', queryLogSchema);