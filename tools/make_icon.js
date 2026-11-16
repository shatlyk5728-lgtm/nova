
const sharp = require('sharp');

sharp('assets/icon.svg', { density: 384 })
  .resize(1024, 1024)
  .png()
  .toFile('assets/icon.png')
  .then(() => console.log('icon.png готов'))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
