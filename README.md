# BasedBracketBuilder

A tournament bracket builder made in Godot with support for multi-bracket tournament types like double elimination. Exports brackets to a readable JSON file.

## Adding Points
Press the "**Add Point**" button in the Tool Box to the left of the screen to add a point.

<img width="870" height="256" alt="PointNode diagram" src="https://github.com/user-attachments/assets/b5b5eee2-6224-4afe-a714-bdc0b33ac194" />

Use the **arrow connector** at the bottom of a point to connect it to another. Click and drag from the arrow to another point to form a bracket. Conneting to a point in another bracket will cause brackets to merge, prioritising the bracket with the lowest point. You cannot connect to a point in the same bracket.

The **square connector in the bottom right** corner can be used to connect to another point in another bracket without merging. This external connection allows brackets to interact with each other.

Click and drag from the **dot connector at the top** of a point to remove connections to that point. You can either drag to a point it's connected to to remove the connection, or drag to an empty space to remove all connections.

## Exporting
Once you've built your brackets, you can export them to a readable JSON file.

When you export this board, for instance -

<img width="241" height="337" alt="bracket example" src="https://github.com/user-attachments/assets/4faa8126-3d12-4c93-89f8-acc247930ee4" />

The structure of the file looks like this:
```
{
   // Bracket
	"bracket1": {
        // Round
		"0": [
            // Point
			{
				"bracket1": 1, // Connection within Bracket
				"bracket2": 0, // Connection to other Bracket
				"index": 0 // Index of this point
			}
		],
		"1": [
			{
				"bracket2": 1,
				"index": 1
			}
		]
	},
	"bracket2": {
		"0": [
			{
				"bracket2": 1,
				"index": 0
			}
		],
		"1": [
			{
				"index": 1
			}
		]
	}
}
```

The file is a nested dictionary with this hierarchy:

  **Bracket -> Round array -> Point**

- Each Bracket is a dictionary of rounds labelled 0 - n
- Each Round is an array of Point dictionaries
- Each Point contains information on what index it is inside a Bracket and the index of points in other Brackets that it connects to
