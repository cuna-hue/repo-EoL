shader_type canvas_item;

/// ===============================================================
/// Recolor Shader
/// - Färbt ausschließlich Graustufenbereiche (R≈G≈B) ein.
/// - Farbige Bereiche bleiben unverändert.
/// - Schattierung (Value) bleibt erhalten.
/// ===============================================================

/// Zielfarbe
uniform vec4 target_color : source_color = vec4(0.25, 0.8, 0.25, 1.0);

/// Maximale Hue-Abweichung in Grad.
/// 0° = keine Variation
/// 180° = komplette Farbkreis-Hälfte
uniform float hue_variation_degrees : hint_range(0.0, 180.0) = 0.0;

/// Position innerhalb der Variation.
/// 0.5 = Originalfarbe
/// 0.0 = maximale negative Abweichung
/// 1.0 = maximale positive Abweichung
uniform float hue_offset : hint_range(0.0, 1.0) = 0.5;

/// Helligkeit
uniform float brightness : hint_range(0.2, 2.0) = 1.0;

/// Sättigung
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

/// Transparenz
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

/// false = gesamtes Sprite
/// true = nur eingefärbte Bereiche
uniform bool opacity_only_recolored = false;

/// Interne Konstante
const float GRAY_TOLERANCE = 0.002;

/// ---------------------------------------------------------------
/// RGB -> HSV
/// ---------------------------------------------------------------
vec3 rgb_to_hsv(vec3 c)
{
	vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);

	vec4 p = mix(vec4(c.bg, K.wz),
				 vec4(c.gb, K.xy),
				 step(c.b, c.g));

	vec4 q = mix(vec4(p.xyw, c.r),
				 vec4(c.r, p.yzx),
				 step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1e-10;

	return vec3(
		abs(q.z + (q.w - q.y) / (6.0 * d + e)),
		d / (q.x + e),
		q.x
	);
}

/// ---------------------------------------------------------------
/// HSV -> RGB
/// ---------------------------------------------------------------
vec3 hsv_to_rgb(vec3 c)
{
	vec3 rgb = clamp(
		abs(mod(c.x * 6.0 + vec3(0.0,4.0,2.0),6.0)-3.0)-1.0,
		0.0,
		1.0
	);

	rgb = rgb * rgb * (3.0 - 2.0 * rgb);

	return c.z * mix(vec3(1.0), rgb, c.y);
}

/// ---------------------------------------------------------------
/// Fragment
/// ---------------------------------------------------------------
void fragment()
{
	vec4 tex = texture(TEXTURE, UV);

	COLOR = tex;

	bool is_gray =
		abs(tex.r - tex.g) < GRAY_TOLERANCE &&
		abs(tex.g - tex.b) < GRAY_TOLERANCE;

	if (tex.a > 0.0 && is_gray)
	{
		vec3 hsv = rgb_to_hsv(target_color.rgb);

		// Grad -> HSV-Kreis
		float hue_delta = hue_variation_degrees / 360.0;

		// hue_offset:
		// 0.0 -> -1
		// 0.5 ->  0
		// 1.0 -> +1
		float variation = (hue_offset * 2.0 - 1.0);

		hsv.x = fract(hsv.x + variation * hue_delta);

		hsv.y = clamp(hsv.y * saturation, 0.0, 1.0);
		hsv.z = clamp(tex.r * brightness, 0.0, 1.0);

		COLOR.rgb = hsv_to_rgb(hsv);

		if (opacity_only_recolored)
			COLOR.a = tex.a * opacity;
	}

	if (!opacity_only_recolored)
		COLOR.a = tex.a * opacity;
}