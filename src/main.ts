import {vec3} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  'tesselations': 6,
  'Lambert Color': [ 255, 180, 203],
  'Animation': true,
  'Surface Movement': false,
  'Animation Speed': 3
};

let planet: Icosphere;
let moon: Icosphere;
let square: Square;
let cube: Cube;
let space: Square;

function loadScene() {
  planet = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  planet.create();
  moon = new Icosphere(vec3.fromValues(-4, 0, 0), 0.3, controls.tesselations);
  moon.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube();
  cube.create();
  space = new Square(vec3.fromValues(0, 0, 0));
  space.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  var colorPicker = gui.addColor(controls, 'Lambert Color'); // color picker for gui
  var animateToggler = gui.add(controls, 'Animation');
  var landMoveToggler = gui.add(controls, 'Surface Movement');
  var animationSpeed = gui.add(controls, 'Animation Speed', 0, 10)

  colorPicker.onChange(function(value : Float32Array) {
    renderer.setGeometryColor(value);
  });

  animateToggler.onChange(function(value : boolean) {
    renderer.setAnimation(value);
  });

  landMoveToggler.onChange(function(value : boolean) {
    renderer.setLandAnimation(value);
  });

  animationSpeed.onChange(function(value : number) {
    renderer.setAnimationSpeed(value);
  });
  
  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const custom = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);

  const planetShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/planet-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/planet-frag.glsl')),
  ]);

  const moonShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    renderer.render(camera, planetShader, [ planet ]);
    renderer.render(camera, moonShader, [ moon ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
