
function blockexchange.clip_area(clip_pos1, clip_pos2, pos1, pos2)
    local clipped_pos1 = {
        x = math.max(clip_pos1.x, pos1.x),
        y = math.max(clip_pos1.y, pos1.y),
        z = math.max(clip_pos1.z, pos1.z)
    }

    local clipped_pos2 = {
        x = math.min(clip_pos2.x, pos2.x),
        y = math.min(clip_pos2.y, pos2.y),
        z = math.min(clip_pos2.z, pos2.z)
    }

    return clipped_pos1, clipped_pos2
end