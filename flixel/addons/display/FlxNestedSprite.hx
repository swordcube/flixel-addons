package flixel.addons.display;

import openfl.geom.ColorTransform;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

using flixel.util.FlxArrayUtil;

/**
 * Some sort of DisplayObjectContainer but very limited.
 * It can contain only other FlxNestedSprites.
 * @author Zaphod
 */
class FlxNestedSprite extends FlxSprite
{
	/**
	 * X position of this sprite relative to parent, 0 by default
	 */
	public var relativeX:Float = 0;

	/**
	 * Y position of this sprite relative to parent, 0 by default
	 */
	public var relativeY:Float = 0;

	/**
	 * Angle of this sprite relative to parent
	 */
	public var relativeAngle:Float = 0;

	/**
	 * Angular velocity relative to parent sprite
	 */
	public var relativeAngularVelocity:Float = 0;

	/**
	 * Angular acceleration relative to parent sprite
	 */
	public var relativeAngularAcceleration:Float = 0;

	public var relativeAlpha:Float = 1;

	/**
	 * Scale of this sprite relative to parent
	 */
	public var relativeScale(default, null):FlxPoint = FlxPoint.get(1, 1);

	/**
	 * Velocity relative to parent sprite
	 */
	public var relativeVelocity(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Acceleration relative to parent sprite
	 */
	public var relativeAcceleration(default, null):FlxPoint = FlxPoint.get();

	/**
	 * All FlxNestedSprites in this list.
	 */
	public var children(default, null):Array<FlxNestedSprite> = [];

	/**
	 * Amount of Graphics in this list.
	 */
	public var count(get, never):Int;

	var _parentRed:Float = 1;
	var _parentGreen:Float = 1;
	var _parentBlue:Float = 1;

	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();

		relativeScale = FlxDestroyUtil.put(relativeScale);
		relativeVelocity = FlxDestroyUtil.put(relativeVelocity);
		relativeAcceleration = FlxDestroyUtil.put(relativeAcceleration);
		children = FlxDestroyUtil.destroyArray(children);
	}

	/**
	 * Adds the FlxNestedSprite to the children list.
	 *
	 * @param	Child	The FlxNestedSprite to add.
	 * @return	The added FlxNestedSprite.
	 */
	public function add(Child:FlxNestedSprite):FlxNestedSprite
	{
		if (children.contains(Child))
			return Child;

		if (children.length > 0 && children[children.length - 1] == null)
		{
			children[children.length - 1] = Child;
		}
		else
		{
			children.push(Child);
		}
		preAdd(Child);

		return Child;
	}

	public function insert(position:Int, Child:FlxNestedSprite):FlxNestedSprite
	{
		if (Child == null)
		{
			FlxG.log.warn("Cannot insert a `null` object into a FlxNestedSprite.");
			return null;
		}

		// Don't bother inserting an Child twice.
		if (children.indexOf(Child) >= 0)
			return Child;

		// First, look if the member at position is null, so we can directly assign the Child at the position.
		if (position < children.length && children[position] == null)
		{
			children[position] = Child;

			preAdd(Child);

			return Child;
		}

		// If we made it this far, we need to insert the Child into the group at the specified position.
		children.insert(position, Child);

		preAdd(Child);

		return Child;
	}

	function preAdd(Child:FlxNestedSprite):Void
	{
		Child.velocity.set(0, 0);
		Child.acceleration.set(0, 0);
		Child.scrollFactor.copyFrom(scrollFactor);

		Child.alpha = Child.relativeAlpha * alpha;
		Child._parentRed = color.redFloat;
		Child._parentGreen = color.greenFloat;
		Child._parentBlue = color.blueFloat;
		Child.color = Child.color;
	}

	/**
	 * Removes the FlxNestedSprite from the children list.
	 *
	 * @param	Child	The FlxNestedSprite to remove.
	 * @return	The removed FlxNestedSprite.
	 */
	public function remove(Child:FlxNestedSprite, Splice:Bool = true):FlxNestedSprite
	{
		if (children == null)
			return null;

		var index:Int = children.indexOf(Child);

		if (index < 0)
			return null;

		if (Splice)
		{
			children.splice(index, 1);
		}
		else
			children[index] = null;

		return Child;
	}

	/**
	 * Removes the FlxNestedSprite from the position in the children list.
	 *
	 * @param	Index	Index to remove.
	 */
	public function removeAt(Index:Int = 0, Splice:Bool = true):FlxNestedSprite
	{
		if (children.length < Index || Index < 0)
			return null;

		var Child = children[Index];
		if (Splice)
		{
			children.splice(Index, 1);
		}
		else
			children[Index] = null;

		return Child;
	}

	/**
	 * Removes all children sprites from this sprite.
	 */
	public function removeAll():Void
	{
		children.clearArray();
	}

	public function preUpdate(elapsed:Float):Void
	{
		#if FLX_DEBUG
		FlxBasic.activeCount++;
		#end

		last.set(x, y);

		for (child in children)
		{
			if (child != null && child.exists && child.active)
				child.preUpdate(elapsed);
		}
	}

	override public function update(elapsed:Float):Void
	{
		preUpdate(elapsed);

		for (child in children)
		{
			if (child != null && child.exists && child.active)
				child.update(elapsed);
		}

		postUpdate(elapsed);
	}

	public function postUpdate(elapsed:Float):Void
	{
		if (moves)
			updateMotion(elapsed);

		wasTouching = touching;
		touching = NONE;
		animation.update(elapsed);

		var delta:Float;
		var velocityDelta:Float;

		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeAngularVelocity, relativeAngularAcceleration, angularDrag, maxAngular, elapsed)
			- relativeAngularVelocity);
		relativeAngularVelocity += velocityDelta;
		relativeAngle += relativeAngularVelocity * elapsed;
		relativeAngularVelocity += velocityDelta;

		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeVelocity.x, relativeAcceleration.x, drag.x, maxVelocity.x, elapsed) - relativeVelocity.x);
		relativeVelocity.x += velocityDelta;
		delta = relativeVelocity.x * elapsed;
		relativeVelocity.x += velocityDelta;
		relativeX += delta;

		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeVelocity.y, relativeAcceleration.y, drag.y, maxVelocity.y, elapsed) - relativeVelocity.y);
		relativeVelocity.y += velocityDelta;
		delta = relativeVelocity.y * elapsed;
		relativeVelocity.y += velocityDelta;
		relativeY += delta;

		for (child in children)
		{
			if (child != null && child.exists && child.active)
			{
				child.velocity.x = child.velocity.y = 0;
				child.acceleration.x = child.acceleration.y = 0;
				child.angularVelocity = child.angularAcceleration = 0;
				child.postUpdate(elapsed);

				var simpleRender = (child.angle == 0 || child.bakedRotationAngle > 0) && child.scale.x == 1 && child.scale.y == 1;

				if (simpleRender)
				{
					child.x = x + child.relativeX - offset.x;
					child.y = y + child.relativeY - offset.y;
				}
				else
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					var cos:Float = Math.cos(radians);
					var sin:Float = Math.sin(radians);

					var dx = width / 2 - child.width / 2 - offset.x;
					dx += scale.x * cos * (child.relativeX - width / 2 + child.width / 2);
					dx -= scale.y * sin * (child.relativeY - height / 2 + child.height / 2);

					var dy = height / 2 - child.height / 2 - offset.y;
					dy += scale.y * cos * (child.relativeY - height / 2 + child.height / 2);
					dy += scale.x * sin * (child.relativeX - width / 2 + child.width / 2);

					child.x = x + dx;
					child.y = y + dy;
				}

				child.angle = angle + child.relativeAngle;
				child.scale.x = scale.x * child.relativeScale.x;
				child.scale.y = scale.y * child.relativeScale.y;

				child.velocity.x = velocity.x;
				child.velocity.y = velocity.y;
				child.acceleration.x = acceleration.x;
				child.acceleration.y = acceleration.y;
			}
		}
	}

	override public function draw():Void
	{
		if (_frame != null)
			super.draw();

		for (child in children)
		{
			if (child != null && child.exists && child.visible)
				child.draw();
		}
	}

	#if FLX_DEBUG
	override public function drawDebug():Void
	{
		super.drawDebug();

		for (child in children)
		{
			if (child != null && child.exists && child.visible)
				child.drawDebug();
		}
	}
	#end

	override function set_alpha(Alpha:Float):Float
	{
		Alpha = FlxMath.bound(Alpha, 0, 1);
		if (Alpha == alpha)
			return alpha;

		alpha = Alpha * relativeAlpha;

		if ((alpha != 1) || (color != 0x00ffffff))
		{
			var red:Float = (color >> 16) * _parentRed / 255;
			var green:Float = (color >> 8 & 0xff) * _parentGreen / 255;
			var blue:Float = (color & 0xff) * _parentBlue / 255;

			if (colorTransform == null)
			{
				colorTransform = new ColorTransform(red, green, blue, alpha);
			}
			else
			{
				colorTransform.redMultiplier = red;
				colorTransform.greenMultiplier = green;
				colorTransform.blueMultiplier = blue;
				colorTransform.alphaMultiplier = alpha;
			}
			useColorTransform = true;
		}
		else
		{
			if (colorTransform != null)
			{
				colorTransform.redMultiplier = 1;
				colorTransform.greenMultiplier = 1;
				colorTransform.blueMultiplier = 1;
				colorTransform.alphaMultiplier = 1;
			}
			useColorTransform = false;
		}
		dirty = true;

		if (children != null)
		{
			for (child in children)
				if (child != null)
					child.alpha = alpha;
		}

		return alpha;
	}

	override function set_color(Color:FlxColor):FlxColor
	{
		Color = Color.to24Bit();

		var combinedRed:Float = (Color >> 16) * _parentRed / 255;
		var combinedGreen:Float = (Color >> 8 & 0xff) * _parentGreen / 255;
		var combinedBlue:Float = (Color & 0xff) * _parentBlue / 255;

		var combinedColor:Int = FlxColor.fromRGBFloat(combinedRed, combinedGreen, combinedBlue, 0);

		if (color == combinedColor)
			return color;

		color = combinedColor;
		if ((alpha != 1) || (color != 0x00ffffff))
		{
			if (colorTransform == null)
			{
				colorTransform = new ColorTransform(combinedRed, combinedGreen, combinedBlue, alpha);
			}
			else
			{
				colorTransform.redMultiplier = combinedRed;
				colorTransform.greenMultiplier = combinedGreen;
				colorTransform.blueMultiplier = combinedBlue;
				colorTransform.alphaMultiplier = alpha;
			}
			useColorTransform = true;
		}
		else
		{
			if (colorTransform != null)
			{
				colorTransform.redMultiplier = 1;
				colorTransform.greenMultiplier = 1;
				colorTransform.blueMultiplier = 1;
				colorTransform.alphaMultiplier = 1;
			}
			useColorTransform = false;
		}

		dirty = true;

		if (FlxG.renderTile)
		{
			color.redFloat = combinedRed;
			color.greenFloat = combinedGreen;
			color.blueFloat = combinedBlue;
		}

		for (child in children)
		{
			if (child == null)
				continue;

			var childColor:Int = child.color;

			var childRed:Float = (childColor >> 16) / (255 * child._parentRed);
			var childGreen:Float = (childColor >> 8 & 0xff) / (255 * child._parentGreen);
			var childBlue:Float = (childColor & 0xff) / (255 * child._parentBlue);

			combinedColor = FlxColor.fromRGBFloat(childRed, childGreen, childBlue, 0);

			child.color = combinedColor;

			child._parentRed = combinedRed;
			child._parentGreen = combinedGreen;
			child._parentBlue = combinedBlue;
		}

		return color;
	}

	override function set_facing(Direction:Int):Int
	{
		super.set_facing(Direction);
		if (children != null)
		{
			for (child in children)
			{
				if (child != null && child.exists && child.active)
					child.facing = Direction;
			}
		}

		return Direction;
	}

	inline function get_count():Int
	{
		return children.length;
	}
}
