const menuToggle = document.querySelector('.toggle');
const showcase = document.querySelector('.showcase');
const button = document.querySelector('.expl');

menuToggle.addEventListener('click', () => {
  menuToggle.classList.toggle('active');
  showcase.classList.toggle('active');
})
button.addEventListener('click', () => {
  menuToggle.classList.toggle('active');
  showcase.classList.toggle('active');
})