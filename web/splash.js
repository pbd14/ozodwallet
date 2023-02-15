var loading = document.createElement('div');
loading.innerHTML = 'Loading';
document.body.appendChild(loading);
/* make text change every two seconds for a random word */
var words = ['OZOD', 'STABLECOIN', 'UZSO', 'FINANCE'];
var i = 0;
setInterval(function() {
  loading.innerHTML = words[i];
  i = (i + 1) % words.length;
}, 300);
/* make text appear in the centre */
loading.style.position = 'absolute';
loading.style.top = '50%';
loading.style.left = '50%';
loading.style.transform = 'translate(-50%, -50%)';
/* use montserrat font, and make text bigger */
loading.style.fontFamily = 'Montserrat';
loading.style.fontSize = '100px';