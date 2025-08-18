import block_wrangler as bw
from block_wrangler.distant_horizons import *
from typing import *
from pathlib import Path
import textwrap as tw
import caseconverter as cc

ROOT_FOLDER = Path(__file__).parents[1]

def main():
    tags = bw.load_tags()
    config = bw.MappingConfig(
        pragma="PROPS_BLOCK_GLSL_INCLUDED"
    )

    Bool = bw.Flag.Conf(function_name=lambda name: f"bp_is{cc.pascalcase(name)}")
    Int = bw.IntFlag.Conf(function_name=lambda name: f"bp_{cc.camelcase(name)}")
    Enum = bw.EnumFlag.Conf(function_name=lambda name: f"bp_{cc.camelcase(name)}")

    mapping = bw.BlockMapping.solve({
        "plant": Bool(tags["plant/thin"], materials=DHMaterial.DH_NONE),
        "tinted_glass": Bool(bw.blocks("minecraft:tinted_glass")),
    }, config=config)

    flag_values: dict[str, dict[Any, list[int]]] = {}

    with open(ROOT_FOLDER / "shaders/block.properties", "w") as f:
        f.write(mapping.render_encoder())
    
    with open(ROOT_FOLDER / "shaders/lib/props/block.glsl", "w") as f:
        f.write(mapping.render_decoder())

    pass

if __name__ == "__main__":
    main()