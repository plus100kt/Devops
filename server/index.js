const path = require('path');
const express = require('express');
const app = express();

const PORT = 4000;

app.use(express.static(path.join(__dirname, '../build')));

const sleep = (ms) => {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
};

const renderIndex = (_, res) => res.send(path.join(__dirname, '../build/index.html'));
const delayResponseAPI = async (_, res) => {
    await sleep(5 * 1000);
    return res.send('OK');
};

app.get('/api', delayResponseAPI);
app.get('/*', renderIndex);

const server = app.listen(PORT, () => {
    console.log(`[Info] Server is listening on port ${PORT}`);
});

/**
 * @param {NodeJS.SignalsListener} signal
 */
const gracefulShutdownHandler = (signal) => {
    console.log(`[${new Date().toISOString()}] ${signal} signal received: closing HTTP server`);
    server.close(() => {
        console.log('HTTP server closed');
    });
};

process.on('SIGTERM', gracefulShutdownHandler);
process.on('SIGINT', gracefulShutdownHandler);
