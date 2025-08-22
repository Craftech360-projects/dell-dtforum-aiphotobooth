export default function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  res.status(200).json({
    status: 'healthy',
    service: 'Dell Photobooth API',
    endpoints: [
      '/api/detect_palm',
      '/api/process_linkedin',
      '/api/health'
    ],
    note: 'For full Python functionality, deploy Python service separately'
  });
}