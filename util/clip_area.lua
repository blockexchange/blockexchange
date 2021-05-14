
function blockexchange.clip_area(bounds, area)
    return {
        pos1 = {
            x = math.max(bounds.pos1.x, area.pos1.x),
            y = math.max(bounds.pos1.y, area.pos1.y),
            z = math.max(bounds.pos1.z, area.pos1.z)
        },
        pos2 = {
            x = math.min(bounds.pos2.x, area.pos2.x),
            y = math.min(bounds.pos2.y, area.pos2.y),
            z = math.min(bounds.pos2.z, area.pos2.z)
        }
    }
end