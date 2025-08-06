from block_wrangler import *
from pathlib import Path
import textwrap as tw
import caseconverter as cc

ROOT_FOLDER = Path(__file__).parent

def main():
    tags = load_tags()
    config = MappingConfig(
        pragma="PROPS_BLOCK_GLSL_INCLUDED"
    )
    mapping = BlockMapping.solve({
        "plant": Flag(blocks(
                # short flowers
                "minecraft:allium",
                "minecraft:azure_bluet",
                "minecraft:blue_orchid",
                "minecraft:cactus_flower",
                "minecraft:cornflower",
                "minecraft:dandelion",
                "minecraft:closed_eyeblossom",
                "minecraft:open_eyeblossom",
                "minecraft:lily_of_the_valley",
                "minecraft:oxeye_daisy",
                "minecraft:poppy",
                "minecraft:red_tulip",
                "minecraft:orange_tulip",
                "minecraft:white_tulip",
                "minecraft:pink_tulip",
                "minecraft:wither_rose",
                # tall flowers
                "minecraft:lilac", 
                "minecraft:peony", 
                "minecraft:sunflower", 
                "minecraft:rose_bush",
                # crops
                "minecraft:wheat",
                "minecraft:potatoes",
                "minecraft:carrots",
                "minecraft:beetroots",
                "minecraft:pumpkin_stem",
                "minecraft:melon_stem",
                # sniffer plants
                "minecraft:torchflower",
                "minecraft:torchflower_crop",
                "minecraft:pitcher_plant",
                "minecraft:pitcher_crop",
                # misc crops
                "minecraft:bamboo_sapling",
                "minecraft:sugar_cane",
                "minecraft:sweet_berry_bush",
                # saplings
                "minecraft:oak_sapling",
                "minecraft:spruce_sapling",
                "minecraft:birch_sapling",
                "minecraft:jungle_sapling",
                "minecraft:acacia_sapling",
                "minecraft:dark_oak_sapling",
                "minecraft:cherry_sapling",
                "minecraft:pale_oak_sapling",
                "minecraft:mangrove_propagule",
                # misc foliage
                "minecraft:short_grass",
                "minecraft:tall_grass",
                "minecraft:dead_bush",
                "minecraft:fern",
                "minecraft:large_fern",
                "minecraft:short_dry_grass",
                "minecraft:tall_dry_grass",
                "minecraft:bush",
                "minecraft:firefly_bush",
            ))
    }, config=config)


    flag_tracker: dict[str, list[int]] = {}
    with open(ROOT_FOLDER / "shaders/block.properties", "w") as f:
        f.write("# auto-generated using block_wrangler\n\n")
        for entry in mapping.mapping:
            f.writelines([
                f"# {', '.join(entry['flags'])}\n"
                f"block.{entry['id']} = {entry['blocks'].render()}\n"
            ])
            for flag in entry['flags']:
                if not (flag in flag_tracker):
                    flag_tracker[flag] = []
                flag_tracker[flag].append(entry['id'])
            pass
    with open(ROOT_FOLDER / "shaders/lib/props/block.glsl", "w") as f:
        f.writelines([
            "// auto-generated using block_wrangler\n\n",
            "#ifndef BLOCK_PROPS_GLSL_INCLUDED\n",
            "#define BLOCK_PROPS_GLSL_INCLUDED\n",
        ])
        for flag, keys in flag_tracker.items():
            f.writelines([
                f"bool is{cc.pascalcase(flag)}(int id) {{\n",
                f"  return {' || '.join(map(lambda key: f'id == {key}', keys))};\n"
                "}\n"
            ])

        f.writelines([
            "#endif\n",
        ])
    pass
if __name__ == "__main__":
    main()