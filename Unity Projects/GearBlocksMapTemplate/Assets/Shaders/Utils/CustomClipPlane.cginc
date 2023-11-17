// Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.

#ifndef CUSTOMCLIPPLANE_CGINC
#define CUSTOMCLIPPLANE_CGINC

#ifdef ENABLE_CUSTOMCLIPPLANE
	uniform float4 _CustomClipPlane;
	#define CUSTOM_CLIP_PLANE( worldPos )	clip( dot( worldPos.xyz, _CustomClipPlane.xyz ) - _CustomClipPlane.w )
#else
	#define CUSTOM_CLIP_PLANE( worldPos )
#endif

#endif // CUSTOMCLIPPLANE_CGINC
