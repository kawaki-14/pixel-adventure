shader_type canvas_item;

uniform float progress: hint_range(0.0, 1.0);
uniform bool reverse = false;
uniform vec2 numberOfTiles = vec2(8.0, 4.5);

void fragment() {
	vec2 uv = UV;
	
	vec2 positionInSquare = uv * numberOfTiles;
	vec2 frac = fract(positionInSquare);
	vec2 direction = abs(frac - 0.5);
	
	float diamond = direction.x + direction.y;
	
	float threshold = progress * 2.0 - uv.x;
	
	if (diamond >= threshold) {
		if (!reverse) {
			discard;
		}
	} else if (reverse) {
		discard;
	}
}