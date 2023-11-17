// <copyright company="SmashHammer Games Inc.">Copyright (C) 2017 - 2023 SmashHammer Games Inc. - All Rights Reserved.</copyright>

using UnityEngine;
using UnityEditor;

namespace SmashHammer.Editor.Environment
{
	public class TerrainDetailsWindow : EditorWindow
	{
#region Serialized data
#endregion // Serialized data

#region Public data
#endregion // Public data

#region Private data
		int					detailLayer = 0;
		int					maxDetailMapLevel = 16;

		struct SplatConfig
		{
			internal int	splatMapLayer;
			internal float	minThreshold;
			internal float	maxThreshold;

			internal void OnGui()
			{
				EditorGUILayout.BeginVertical( "Box" );

				splatMapLayer = EditorGUILayout.IntField( "Splat Map Layer", splatMapLayer );
				minThreshold = EditorGUILayout.Slider( "Min Threshold", minThreshold, 0.0f, 1.0f );
				maxThreshold = EditorGUILayout.Slider( "Max Threshold", maxThreshold, 0.0f, 1.0f );

				EditorGUILayout.EndVertical();
			}
		}
		SplatConfig			splatConfig = new SplatConfig() { splatMapLayer = 0, minThreshold = 0.0f, maxThreshold = 1.0f };
		bool				enableSplat = false;

		struct NoiseConfig
		{
			internal int	octaves;
			internal float	amplitude;
			internal float	persistence;
			internal float	frequency;

			internal void OnGui()
			{
				EditorGUILayout.BeginVertical( "Box" );

				octaves = EditorGUILayout.IntSlider( "Octaves", octaves, 1, 8 );
				amplitude = EditorGUILayout.Slider( "Amplitude", amplitude, 0.0f, 1.0f );
				persistence = EditorGUILayout.Slider( "Persistence", persistence, 0.0f, 1.0f );
				frequency = EditorGUILayout.FloatField( "Frequency", frequency );

				EditorGUILayout.EndVertical();
			}
		}
		NoiseConfig			noiseConfig = new NoiseConfig() { octaves = 4, amplitude = 0.5f, persistence = 0.5f, frequency = 1000.0f };
		bool				enableNoise = false;
#endregion // Private data

#region Constructors
#endregion // Constructors

#region Unity messages
		void OnGUI()
		{
			GUILayout.Label( "Generate Details", EditorStyles.boldLabel );

			EditorGUILayout.BeginVertical( "Box" );

			detailLayer = EditorGUILayout.IntField( "Detail Layer", detailLayer );
			maxDetailMapLevel = EditorGUILayout.IntSlider( "Max Detail Map Level", maxDetailMapLevel, 0, 16 );

			EditorGUILayout.Space();

			enableSplat = EditorGUILayout.Toggle( "Apply From Splat", enableSplat );
			if( enableSplat )
			{
				splatConfig.OnGui();
			}

			EditorGUILayout.Space();

			enableNoise = EditorGUILayout.Toggle( "Modulate With Noise", enableNoise );

			if( enableNoise )
			{
				noiseConfig.OnGui();
			}

			EditorGUILayout.Space();

			if( GUILayout.Button( "Apply", GUILayout.Width( 75.0f ) ) )
            {
				foreach( Transform transform in Selection.transforms )
				{
					GenerateDetailMap( transform.GetComponent<Terrain>(), detailLayer );
				}
			}
			EditorGUILayout.EndVertical();
		}
#endregion // Unity messages

#region Interface methods
#endregion // Interface methods

#region Public methods
#endregion // Public methods

#region Private methods
		[MenuItem( "Window/Terrain/Terrain Details", false, 0 )]
		static void CreateWindow()
		{
			TerrainDetailsWindow window = GetWindow<TerrainDetailsWindow>( "Terrain Details" );
			window.Show();
		}

		void GenerateDetailMap( Terrain terrain, int detailLayer )
		{
			if( terrain != null )
			{
				TerrainData terrainData = terrain.terrainData;

				// Clamp indices to valid range.
				int splatMapLayer = Mathf.Clamp( splatConfig.splatMapLayer, 0, terrainData.alphamapLayers - 1 );
				detailLayer = Mathf.Clamp( detailLayer, 0, terrainData.detailPrototypes.Length - 1 );

				// Get splat maps.
				float[,,] splatMaps = terrainData.GetAlphamaps( 0, 0, terrainData.alphamapWidth, terrainData.alphamapHeight );

				// Allocate buffer for detail map.
				int[,] detailMap = new int[terrainData.detailWidth, terrainData.detailHeight];

				float normalizeWidth = 1.0f / terrainData.detailWidth;
				float normalizeHeight = 1.0f / terrainData.detailHeight;
				for( int x = 0; x < terrainData.detailWidth; ++x )
				{
					for( int y = 0; y < terrainData.detailHeight; ++y )
					{
						float detailAmount = 1.0f;

						// Apply splat value (remapping between thresholds) if enabled.
						if( enableSplat )
						{
							int xSplatMap = Mathf.RoundToInt( x * normalizeWidth * terrainData.alphamapWidth );
							int ySplatMap = Mathf.RoundToInt( y * normalizeHeight * terrainData.alphamapHeight );

							detailAmount *= splatMaps[xSplatMap, ySplatMap, splatMapLayer];
							detailAmount = Maths.MathUtils.Remap01( detailAmount, splatConfig.minThreshold, splatConfig.maxThreshold );
						}

						// Apply noise if enabled.
						if( enableNoise )
						{
							detailAmount *= Maths.MathUtils.PerlinFractal( x * normalizeWidth, y * normalizeHeight, noiseConfig.octaves, noiseConfig.amplitude, noiseConfig.persistence, noiseConfig.frequency );
						}

						// Set level in detail map.
						detailMap[x, y] = Mathf.RoundToInt( maxDetailMapLevel * detailAmount );
					}
				}

				// Set detail map.
				terrainData.SetDetailLayer( 0, 0, detailLayer, detailMap );
			}
		}
#endregion // Private methods

#region Remote methods
#endregion // Remote methods
	}
}
