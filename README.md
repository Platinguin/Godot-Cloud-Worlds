# Godot-Cloud-Worlds

This is more or less a prototype to see if its possible to implement volumetric clouds which can be reached by the player.

The project was created with Godot 4.2.2 win64

Technical Details:

The clouds are generated via a pre-baked sdf texture. This ensures good performance, as the raymarch loop knows how far it has to step to reach the clouds. As soon as the raymarcher hits the cloud surface, it goes into a fixed step sampling mode to sample the volume texture.
The lighting is calculated afterwards in a deferred manner. There is only one light-march loop per pixel. I know its not physically correct. Normally you would have to calculate the light at every step within the cloud, but the visual difference is minimal and it saves performance. The light-march steps are using the same sdf texture to determine how far they have to march. (the steps are not in a fixed size) They are also reduced over distance to save performance.

Known Issues:
- To see the clouds in the editor, you have to increase your camera z-clipping plane first
- The clouds can't generate a cubemap reflection (to make this work they have to be rendered differently, to generate a radiance map via the environment world sky)
- The clouds can't generate shadows to affect other objects in the scene (as of now I avoided generating another shadow map, it is possible however but needs alot of work)
- The clouds cause sorting issues with other alpha blended materials (as they are rendered as of post-effect it's not easy to make this work)

Feel free to edit them or use the code for your own Godot project.

Future Ideas:

Most likely I will use this tech to create a skybox baker to make the clouds static, but as cheap as they can get with highest quality looks. So you could have a semi-realtime sky with clouds which are generated via GPU in the background. In the end they would be as cheap as a standard HDRI skybox, but you would still have the customizablity of a dynamic sky. (it would however take like a second to generate this one, so it's not realtime)
