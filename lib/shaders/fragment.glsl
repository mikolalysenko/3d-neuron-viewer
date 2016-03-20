precision highp float;

uniform mat4 clipToWorld;
uniform sampler2D voxels;
uniform vec3 shape;       //Volume resolution
uniform vec2 zshape;      //Z factorization
uniform vec2 tshape;      //Texture resolution

uniform float intensity, transparency, stepSize;

varying vec3 rayOrigin;

vec2 zcoords(float iz) {
  float row    = floor(iz / zshape.y);
  float column = floor(iz - zshape.y * row);
  return vec2(column, row) * shape.xy;
}

vec4 getVoxel(vec3 p) {
  //Calculate clamp weight
  vec2 wp = step(0.0, p.xy) * step(-shape.xy, -p.xy);
  float w = wp.x * wp.y *
    step(0.0, p.z) *
    step(-shape.z, -p.z);

  //Get offset in xy slice
  vec2 coord = p.xy;

  //Get z-coordinate
  float iz = floor(shape.z*fract(p.z/shape.z));

  //Read pixels
  vec4 voxel = texture2D(voxels, (coord + zcoords(iz)) / tshape);

  return w * vec4(intensity * voxel.rrr, pow(voxel.r, transparency));
}

float rayStep(vec3 coordinate, vec3 direction) {
  vec3 f = fract(coordinate);
  vec3 dt_pos = (1.0-f) / direction;
  vec3 dt_neg = -f / direction;
  vec3 dt = mix(dt_neg, dt_pos, step(0.0, direction));
  return max(min(min(dt.x, dt.y), dt.z), 0.001);
}

vec4 over(vec4 ca, vec4 cb) {
  float ao = 1.0 - (1.0 - ca.a) * (1.0 - cb.a);
  return vec4(ao * mix(cb.rgb, ca.rgb, ca.a / ao), ao);
}

float alphaWeight(float ao, float dt) {
  return 1.0 - exp(-4.0 * ao * dt);
}

vec4 castRay(vec3 origin, vec3 direction) {
  vec4 c = vec4(0.0,0.0,0.0,0.0);
  for(int i=0; i<500; ++i) {
    //Calculate step
    float dt = rayStep(origin, direction);

    //Read voxel
    vec4 ci = getVoxel(origin);

    //Update color
    c = over(c, vec4(ci.rgb, alphaWeight(ci.a, dt)));

    //March ray
    origin += direction * dt * stepSize;
  }

  return c;
}

void main() {
  vec3 eye = clipToWorld[3].xyz / clipToWorld[3].w;

  vec3 direction = normalize(shape*(rayOrigin - eye));
  vec3 origin    = shape * (0.5 * (rayOrigin + 1.0));

  vec4 hitColor = castRay(origin, direction);
  gl_FragColor = vec4(hitColor.rgb / max(hitColor.a,0.001), hitColor.a);
}
