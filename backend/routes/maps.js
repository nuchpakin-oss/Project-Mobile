const express = require('express');
const router = express.Router();

router.get('/reverse-geocode', async (req, res) => {
  try {
    const { lat, lng } = req.query;

    const url =
      `https://maps.googleapis.com/maps/api/geocode/json` +
      `?latlng=${lat},${lng}` +
      `&language=th` +
      `&region=th` +
      `&key=${process.env.GOOGLE_MAPS_SERVER_KEY}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'OK' && data.results?.length) {
      return res.json({
        success: true,
        address: data.results[0].formatted_address,
      });
    }

    return res.status(400).json({
      success: false,
      status: data.status,
      message: 'Geocoding failed',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

router.get('/search-geocode', async (req, res) => {
  try {
    const { q } = req.query;

    const url =
      `https://maps.googleapis.com/maps/api/geocode/json` +
      `?address=${encodeURIComponent(q)}` +
      `&language=th` +
      `&region=th` +
      `&key=${process.env.GOOGLE_MAPS_SERVER_KEY}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'OK' && data.results?.length) {
      const result = data.results[0];
      return res.json({
        success: true,
        address: result.formatted_address,
        lat: result.geometry.location.lat,
        lng: result.geometry.location.lng,
      });
    }

    return res.status(400).json({
      success: false,
      status: data.status,
      message: 'Search geocoding failed',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;