import express from 'express';
import WwiRoutes from './routes/wwi.routes.js';

const app = express();

app.use(express.json({ limit: '2mb' }));
app.use('/api', WwiRoutes);

app.use((error, req, res, next) => {
	if (error.type === 'entity.too.large') {
		return res.status(413).json({
			error: 'La solicitud supera el tamaño permitido.',
			code: 'ARCHIVO_DEMASIADO_GRANDE'
		});
	}

	if (error instanceof SyntaxError) {
		return res.status(400).json({
			error: 'El JSON de la solicitud no es válido.',
			code: 'DATOS_INVALIDOS'
		});
	}

	console.error('Error no esperado en la API:', error.message);
	return res.status(500).json({
		error: 'Ocurrió un error interno al procesar la solicitud.',
		code: 'ERROR_INTERNO'
	});
});

export default app;
