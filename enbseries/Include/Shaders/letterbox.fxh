//==========================================//
// Letterbox shader by Adyss                //
// Features: rotation, pillarboxes,         //
// depthawareness and customizable color    //
// Feel free to use this in your own presets//
//==========================================//
// the Color.a portion is to create a mask of where the letterboxes are in alpha channel. This is used for underwater shaders wich usually just draw over Letterboxes

float3 applyLetterbox(float3 Color, float Depth, float2 coord)
{
	float 	 rotSin 		= sin(BoxRotation);
	float	 rotCos 		= cos(BoxRotation);
	float2x2 rotationMatrix = float2x2(rotCos, -rotSin, rotSin, rotCos);
			 rotationMatrix *= 0.5; // Matrix Correction to fix on center point
			 rotationMatrix += 0.5;
			 rotationMatrix = rotationMatrix * 2 - 1;
	float2	 rotationCoord  = mul(coord - 0.5, rotationMatrix);
			 rotationCoord += 0.5;

	if(Depth > LetterboxDepth * 0.01)
	{
		if(rotationCoord.x > 1.0 - vBoxSize || rotationCoord.y < hBoxSize)
		{
			Color = BoxColor;
		}
		if (rotationCoord.y > 1.0 - hBoxSize || rotationCoord.x < vBoxSize)
		{
			Color = BoxColor;
		}
	}
	return Color;
}
