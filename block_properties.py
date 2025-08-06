from block_wrangler import *
from pathlib import Path
import textwrap as tw

ROOT_FOLDER = Path(__file__).parent

def main():
    tags = load_tags()
    config = MappingConfig(
        pragma="PROPS_BLOCK_GLSL_INCLUDED"
    )
    mapping = BlockMapping.solve({
        "plant": Flag(
            tags["minecraft:small_flowers"]
            .union(tags["minecraft:crops"])
            .union(tags["minecraft:saplings"])
            .union(blocks(
                "minecraft:lilac", 
                "minecraft:peony", 
                "minecraft:sunflower", 
                "minecraft:rose_bush"
            ))
        )
    }, config=config)

    with open(ROOT_FOLDER / "shaders/block.properties", "w") as f:
        f.write(mapping.render_encoder())
    with open(ROOT_FOLDER / "shaders/lib/props/block.glsl", "w") as f:
        f.write(mapping.render_decoder())
    pass
if __name__ == "__main__":
    main()