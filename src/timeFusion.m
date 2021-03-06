function [total_grid, new_grid] = timeFusion( obj_new_grid, obj_total_grid,...
                                            changes)
%% Fusion between local grid map and global grid map

dempster_normalization = 1;
total_grid=obj_total_grid.X; obj_total_grid.X=[];
new_grid=obj_new_grid.X; obj_new_grid.X=[];

for i = 1:size(changes,1)
    row =  changes(i,1);
    col = changes(i,2);
    
    m1 = total_grid(row,col,1:4);
    m2 = new_grid(row,col,1:4);
    new_grid(row,col,:) = [0,0,0,1];
    m1(3) = 0.0;
    m2(3) = 0.0;
    
    %% Conjunctive rule
    if (m1(4) ~= 1.0 && m2(4) ~= 1.0) || ~isequal(m1,m2)
        free = m1(4) * m2(1) + m1(1) * m2(1) + m1(1) * m2(4); 
        occ = m1(4) * m2(2) + m1(2) * m2(2) + m1(2) * m2(4); 
        conf = m1(3) * m2(1) + m1(3) * m2(2) + m1(3) * m2(3) + ...
            m1(3) * m2(4) + m2(3) * m1(1) + m2(3) * m1(2) + ...
            m2(3) * m1(3) + m1(1) * m2(2) + m1(2) * m2(1);
        unk = m1(4) * m2(4);
        
        %% Normalization
        if dempster_normalization
            free = fix((free / (1 - conf)) * 100) / 100;
            occ = fix((occ / (1 - conf)) * 100) / 100;
            unk = fix((unk / (1 - conf)) * 100) / 100;
            if (free + occ + unk) < 1.0
               unk = unk + (1 - (free + occ + unk));
            end
        end
        
        total_grid(row,col,1:4) = [free,occ,conf,unk];
    end
    
end

end

