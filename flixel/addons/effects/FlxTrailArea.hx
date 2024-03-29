package flixel.addons.effects;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * This provides an area in which the added sprites have a trail effect. Usage: Create the FlxTrailArea and
 * add it to the display. Then add all sprites that should have a trail effect via the add function.
 * @author KeyMaster
 */
class FlxTrailArea extends FlxSprite
{
	/**
	 * How often the trail is updated, in frames. Default value is 2, or "every frame".
	 */
	public var delay:Int = 2;

	/**
	 * If this is true, the render process ignores any color/scale/rotation manipulation of the sprites
	 * with the advantage of being faster
	 */
	public var simpleRender:Bool = false;

	/**
	 * Specifies the blendMode for the trails.
	 * Ignored in simple render mode. Only works on the flash target.
	 */
	public var blendMode:BlendMode = null;

	/**
	 * Stores all sprites that have a trail.
	 */
	public var group:FlxTypedGroup<FlxSprite>;

	/**
	 * The bitmap's red value is multiplied by this every update
	 */
	public var redMultiplier:Float = 1;

	/**
	 * The bitmap's green value is multiplied by this every update
	 */
	public var greenMultiplier:Float = 1;

	/**
	 * The bitmap's blue value is multiplied by this every update
	 */
	public var blueMultiplier:Float = 1;

	/**
	 * The bitmap's alpha value is multiplied by this every update
	 */
	public var alphaMultiplier:Float;

	/**
	 * The bitmap's red value is offsettet by this every update
	 */
	public var redOffset:Float = 0;

	/**
	 * The bitmap's green value is offsettet by this every update
	 */
	public var greenOffset:Float = 0;

	/**
	 * The bitmap's blue value is offsettet by this every update
	 */
	public var blueOffset:Float = 0;

	/**
	 * The bitmap's alpha value is offsettet by this every update
	 */
	public var alphaOffset:Float = 0;

	/**
	 * Counts the frames passed.
	 */
	var _counter:Int = 0;

	/**
	 * Internal width variable
	 * Initialized to 1 to prevent invalid bitmapData during construction
	 */
	var _width:Float = 1;

	/**
	 * Internal height variable
	 * Initialized to 1 to prevent invalid bitmapData during construction
	 */
	var _height:Float = 1;

	/**
	 * Internal helper var, linking to area's pixels
	 */
	var _areaPixels:BitmapData;

	/**
	 * Creates a new FlxTrailArea, in which all added sprites get a trail effect.
	 *
	 * @param	X				x position of the trail area
	 * @param	Y				y position of the trail area
	 * @param	Width			The width of the area - defaults to FlxG.width
	 * @param	Height			The height of the area - defaults to FlxG.height
	 * @param	AlphaMultiplier By what the area's alpha is multiplied per update
	 * @param	Delay			How often to update the trail. 1 updates every frame
	 * @param	SimpleRender 	If simple rendering should be used. Ignores all sprite transformations
	 * @param	Antialiasing	If sprites should be smoothed when drawn to the area. Ignored when simple rendering is on
	 * @param	TrailBlendMode 	The blend mode used for the area. Only works in flash
	 */
	public function new(X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, AlphaMultiplier:Float = 0.8, Delay:Int = 2, SimpleRender:Bool = false,
			Antialiasing:Bool = false, ?TrailBlendMode:BlendMode)
	{
		super(X, Y);

		group = new FlxTypedGroup<FlxSprite>();

		// Sync variables
		delay = Delay;
		simpleRender = SimpleRender;
		blendMode = TrailBlendMode;
		antialiasing = Antialiasing;
		alphaMultiplier = AlphaMultiplier;

		setSize(Width, Height);
		pixels = _areaPixels;
	}

	/**
	 * Sets the FlxTrailArea to a new size. Clears the area!
	 *
	 * @param	Width		The new width
	 * @param	Height		The new height
	 */
	override public function setSize(Width:Float, Height:Float)
	{
		Width = (Width <= 0) ? FlxG.width : Width;
		Height = (Height <= 0) ? FlxG.height : Height;

		if ((Width != _width) || (Height != _height))
		{
			_width = Width;
			_height = Height;
			_areaPixels = new BitmapData(Std.int(_width), Std.int(_height), true, FlxColor.TRANSPARENT);
		}
	}

	override public function destroy():Void
	{
		group = FlxDestroyUtil.destroy(group);
		blendMode = null;

		if (pixels != _areaPixels)
		{
			_areaPixels.dispose();
		}
		_areaPixels = null;

		super.destroy();
	}

	override public function draw():Void
	{
		// Count the frames
		_counter++;

		if (_counter >= delay)
		{
			_counter = 0;
			_areaPixels.lock();
			// Color transform bitmap
			var cTrans = new ColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset);
			_areaPixels.colorTransform(new Rectangle(0, 0, _areaPixels.width, _areaPixels.height), cTrans);

			// Copy the graphics of all sprites on the renderBitmap
			for (member in group.members)
			{
				if (member.exists)
				{
					var finalX = member.x - x - member.offset.x;
					var finalY = member.y - y - member.offset.y;

					if (simpleRender)
					{
						_areaPixels.copyPixels(member.updateFramePixels(), new Rectangle(0, 0, member.frameWidth, member.frameHeight),
							new Point(finalX, finalY), null, null, true);
					}
					else
					{
						var scaled = (member.scale.x != 1) || (member.scale.y != 1);
						var rotated = (member.angle != 0) && (member.bakedRotationAngle <= 0);
						_matrix.identity();
						if (rotated || scaled)
						{
							_matrix.translate(-member.origin.x, -member.origin.y);
							if (scaled)
							{
								_matrix.scale(member.scale.x, member.scale.y);
							}
							if (rotated)
							{
								_matrix.rotate(member.angle * FlxAngle.TO_RAD);
							}
							_matrix.translate(member.origin.x, member.origin.y);
						}
						_matrix.translate(finalX, finalY);
						_areaPixels.draw(member.updateFramePixels(), _matrix, member.colorTransform, blendMode, null, antialiasing);
					}
				}
			}

			_areaPixels.unlock();
			pixels = _areaPixels;
		}

		super.draw();
	}

	/**
	 * Wipes the trail area
	 */
	public inline function resetTrail():Void
	{
		_areaPixels.fillRect(new Rectangle(0, 0, _areaPixels.width, _areaPixels.height), FlxColor.TRANSPARENT);
	}

	/**
	 * Adds a FlxSprite to the FlxTrailArea. Not an add() in the traditional sense,
	 * this just enables the trail effect for the sprite. You still need to add it to your state for it to update!
	 *
	 * @param	Sprite		The sprite to enable the trail effect for
	 * @return 	The FlxSprite, useful for chaining stuff together
	 */
	public inline function add(Sprite:FlxSprite):FlxSprite
	{
		return group.add(Sprite);
	}

	/**
	 * Redirects width to _width
	 */
	override inline function get_width():Float
	{
		return _width;
	}

	/**
	 * Setter for width, defaults to FlxG.width, creates new _rendeBitmap if neccessary
	 */
	override function set_width(Width:Float):Float
	{
		Width = (Width <= 0) ? FlxG.width : Width;

		if (Width != _width)
		{
			_areaPixels = new BitmapData(Std.int(Width), Std.int(_height), true, FlxColor.TRANSPARENT);
		}

		return _width = Width;
	}

	/**
	 * Redirects height to _height
	 */
	override inline function get_height():Float
	{
		return _height;
	}

	/**
	 * Setter for height, defaults to FlxG.height, creates new _rendeBitmap if neccessary
	 */
	override function set_height(Height:Float):Float
	{
		Height = (Height <= 0) ? FlxG.height : Height;

		if (Height != _height)
		{
			_areaPixels = new BitmapData(Std.int(_width), Std.int(Height), true, FlxColor.TRANSPARENT);
		}

		return _height = Height;
	}
}
