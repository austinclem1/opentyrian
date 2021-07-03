#define FONT_SHAPES       0
#define SMALL_FONT_SHAPES 1
#define TINY_FONT         2
#define PLANET_SHAPES     3
#define FACE_SHAPES       4
#define OPTION_SHAPES     5 /*Also contains help shapes*/
#define WEAPON_SHAPES     6
#define EXTRA_SHAPES      7 /*Used for Ending pics*/

#define SPRITE_TABLES_MAX        8
#define SPRITES_PER_TABLE_MAX  151

typedef struct
{
	uint16_t width, height;
	uint16_t size;
	uint8_t *data;
}
Sprite;

typedef struct
{
	unsigned int count;
	Sprite sprite[SPRITES_PER_TABLE_MAX];
}
Sprite_array;

extern Sprite_array sprite_table[SPRITE_TABLES_MAX];

typedef struct
{
	unsigned int size;
	uint8_t *data;
}
Sprite2_array;

extern Sprite2_array eShapes[6];
extern Sprite2_array shapesC1, shapes6, shapes9, shapesW2;
