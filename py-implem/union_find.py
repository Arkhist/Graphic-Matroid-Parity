def uf_find(uf_set: list[int], tag: int):
    if uf_set[tag] == tag:
        return tag
    uf_set[tag] = uf_find(uf_set, uf_set[tag])
    return uf_set[tag]

def uf_union(uf_set: list[int], tag1: int, tag2: int):
    tag1 = uf_find(uf_set, tag1)
    tag2 = uf_find(uf_set, tag2)
    uf_set[tag1] = tag2
