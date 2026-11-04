import express from 'express';
import WwiRoutes from './routes/wwi.routes.js';

const app = express();

app.use(express.json());
app.use('/api', WwiRoutes);

export default app;
