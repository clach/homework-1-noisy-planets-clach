import {mat4, vec4} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  color: vec4 = vec4.fromValues(1, 0.78, 0.80, 1); // default geometry color
  time: number = 0;
  animation: boolean = true;
  landTime: number = 0;
  landAnimation: boolean = false;
  animationSpeed: number = 5;

  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  setGeometryColor(color: Float32Array) {
    this.color = vec4.fromValues(color[0] / 255, color[1] / 255, color[2] / 255, 1);
  }

  setAnimation(animateOn: boolean) {
    this.animation = animateOn;
  }

  setLandAnimation(landAnimateOn: boolean) {
    this.landAnimation = landAnimateOn;
  }

  setAnimationSpeed(speed: number) {
    this.animationSpeed = speed;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>) {
    let model = mat4.create();
    let viewProj = mat4.create();
    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(this.color);

    prog.setLandMoveTime(this.landTime);
    if (this.landAnimation == true) {
      this.landTime += this.animationSpeed;
    }

    prog.setTime(this.time);
    if (this.animation == true) {
      this.time += this.animationSpeed;
    }
    

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
