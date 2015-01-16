CREATE OR REPLACE FUNCTION event.usp_event_add_update(
    i_sess TEXT,
    i_evt_name TEXT,
    i_evt_description TEXT,
    i_evt_start TIMESTAMP WITH TIME ZONE,
    i_evt_end TIMESTAMP WITH TIME ZONE,
    i_evt_id BIGINT,
    i_evt_geo_id BIGINT,
    i_band TEXT,
    i_img TEXT,
    i_img_type TEXT,
    i_lat NUMERIC(20,17),
    i_lng NUMERIC(20,17),
    i_addy TEXT
)
RETURNS TABLE(
    event_id BIGINT,
    status_id INT,
    status_desc TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    _user BIGINT;
    _evt_id BIGINT;
    _add_id BIGINT;
    _status_id INT;
    _status_desc TEXT;
    _pass TEXT;
BEGIN
    
    SELECT asr_user 
      INTO _user
      FROM sess.usp_sess_check(i_sess);
      
    SELECT add_id
      INTO _add_id
      FROM geo.address
     WHERE add_formatted = i_addy;
     
    IF _add_id IS NULL THEN
        INSERT INTO geo.address (add_lat, add_lng, add_formatted)
        VALUES (i_lat, i_lng, i_addy)
     RETURNING add_id INTO _add_id;
    END IF;
    IF i_evt_id IS NOT NULL THEN 
        UPDATE event.event 
           SET evt_description = i_evt_description,
               evt_name = i_evt_name,
               evt_start = i_evt_start,
               evt_end = i_evt_end,
               evt_add_id = i_add_id,
               evt_modified = now()
         WHERE evt_id = i_evt_id;
        
        IF i_img IS NOT NULL THEN
            UPDATE event.event_image
               SET evi_default = FALSE
             WHERE evi_evt_id = i_evt_id;
        END IF;
        _evt_id = i_evt_id;
        _status_id = 200;
        _status_desc = 'evt_id updated: ' || i_evt_id::text;
    ELSE
        INSERT INTO event.event (evt_asr_user, evt_name, evt_description, evt_start, evt_end, evt_geo_id, evt_add_id)
        VALUES (_user, i_evt_name, i_evt_description, i_evt_start, i_evt_end, i_evt_geo_id, _add_id)
        RETURNING evt_id INTO _evt_id;
        _status_id = 200;
        _status_desc = 'evt_id inserted: ' || _evt_id::text;
    END IF;
    IF i_img IS NOT NULL THEN
        INSERT INTO event.event_image (evi_evt_id, evi_img, evi_type, evi_default)
        SELECT _evt_id, i_img, i_img_type, true;
    END IF;
    RETURN QUERY SELECT _evt_id, _status_id, _status_desc;
END;
$$;