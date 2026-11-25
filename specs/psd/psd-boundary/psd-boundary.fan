# Photoshop documents at the edges, besides those of psd: 32-bit grayscale
# and RGB (floats); layers of 16- and 32-bit documents, in 'Lr16' and 'Lr32'
# after an empty layer info; layer masks; a group around the layers (the
# divider that closes it and the layer that opens it, open or closed); empty
# layers; layers that reach past the edges of the canvas; clipped layers;
# every blend mode; layer names of up to 255 characters of any Latin-1
# value; a negative layer count (the first alpha channel is the merged
# image's transparency); the global layer mask; ZIP compression with and
# without prediction, for layers and the merged image; the large document
# format (PSB: version 2, 8-byte lengths, 4-byte row counts); up to 56
# channels; a merged image said not to be the real one; an XMP packet; and
# resources of no data.
#
# TODO:
# * Thumbnails, ICC profiles, paths and the other resources whose contents
#   readers interpret, and adjustment, type and smart-object layers, are
#   left out.
# * Documents larger than 64x64 are left out: Fandango 1.3.1 runs out of
#   memory making images of many pixels.

include("psd/psd.fan")

<psd_draft> ::= <mode> <width> <height> <extra_channels> <more_channels>? <merged_packing> <kind> <seed> <resources> \
                <layers> <grouped>? <merged_alpha>? <global_mask>? <deep_layers>? <psb>?
<mode> ::= b'0' | b'1' <depth> | b'2' | b'3' <depth> | b'4' <depth> \
         | b'7' <depth> <multi_count> | b'8' <depth> <duotone_data> | b'9' <depth> \
         | b'1' <deep> | b'3' <deep>
<deep> ::= b'32'
<more_channels> ::= rb'[\x00-\xff]'
<merged_packing> ::= b'r' | b'l' | b'z' | b'p'
<resource> ::= b'R' <res_values> | b'V' | b'v' | b'X' | b'A' <angle> | b'U' <res_id> <res_name> <res_data>
<res_data> ::= rb'[\x00-\xff]{0,32}'

<layer> ::= <rect> <layer_alpha> <blend> <opacity> <flags> <layer_name> <layer_packing> <kind> <seed> \
            <layer_mask>? <empty_layer>? <beyond>? <clipping>?
<layer_mask> ::= rb'[\x00-\xff]{2}'
<empty_layer> ::= b'e'
<beyond> ::= b'b'
<clipping> ::= b'c'
<blend> ::= b'norm' | b'diss' | b'dark' | b'mul ' | b'idiv' | b'lbrn' | b'dkCl' | b'lite' | b'scrn' | b'div ' \
          | b'lddg' | b'lgCl' | b'over' | b'sLit' | b'hLit' | b'vLit' | b'lLit' | b'pLit' | b'hMix' | b'diff' \
          | b'smud' | b'fsub' | b'fdiv' | b'hue ' | b'sat ' | b'colr' | b'lum '
<layer_name> ::= rb'[\x20-\x7e]{0,20}' | rb'[\x20-\xff]{200,255}'
<layer_packing> ::= b'r' | b'l' | b'z' | b'p'
<grouped> ::= rb'[\x00-\xff]'
<merged_alpha> ::= b'-'
<global_mask> ::= rb'[\x00-\xff]{10}'
<deep_layers> ::= b'L'
<psb> ::= b'B'
