function [grid_evidential, aging_camera, changes] = stereoMapping( ...
    obj_stereo_grid, U, grid_parameters, pose_camera, obj, G_ins_camera, ...
    time, camera_params, limits, scale)
aging_camera=obj.X; obj.X=[];
grid_evidential=obj_stereo_grid.X; obj_stereo_grid.X=[];

%% Parameters
[~,n] = size(U);
start_j = 60 * scale;
end_j = n - start_j;
max_distance = 25;
max_dist_map = max_distance / grid_parameters.resolution;
focal = camera_params.f * scale;
cu = camera_params.cu * scale;
baseline = camera_params.b;
confidence_camera = 0.9;
origin = grid_parameters.origin;
res = grid_parameters.resolution;
grid_size_x = grid_parameters.size_grid_x;
grid_size_y = grid_parameters.size_grid_y;
grid = zeros(grid_size_x, grid_size_y);
position_world = [pose_camera(1,4), pose_camera(2,4)];
position = round(position_world/res + grid_parameters.origin);

%% Creation of evidential grid of obstacles detected by the camera
changes = zeros(32 * (end_j -start_j) ,2);
count_changes = 1;

%% Loop through the disparities 
for d = 5:25
    for j = start_j:end_j
        p = U(d,j);
        if p > 10  
            %% Map to world coordinates
            x = round(baseline/2.0 + (baseline * (j - cu))/d);
            y = round(focal * baseline / d);
            [points] = cameraToWorld( x, y, j, d, res, camera_params);

            %% Map to grid coordinates
            if size(points,1) > 0
                points2 = [points(:,2),points(:,1), ones(size(points,1),2)];
                points2 = (pose_camera * G_ins_camera * points2')' ;

                for point = 1:size(points,1)
                    xi = points2(point,1);
                    yi = points2(point,2);
                    prob = points(point,3);

                    y = ceil((yi)/res + origin(2));
                    x = ceil(xi/res + origin(1));

                    if(x > limits(1) && x < limits(2) && y > limits(3) && ...
                        y < limits(4))
                           distance = sqrt((x-position(1))^2 + ...
                               (y-position(2))^2);
                           if distance < max_dist_map
                               if grid(x,y) == 0
                                  changes(count_changes,:) = [x,y];
                                  count_changes = count_changes + 1; 
                               end
                               grid(x,y) = grid(x,y) + prob ;
                           end
                    end
                end
            end
        end
        
    end
    
end

%% Activation function
coef_tanh = 0.05;
for i = 1:count_changes-1
    x = changes(i,1);
    y = changes(i,2);
    p_cell = tanh(coef_tanh*grid(x,y));
    grid_evidential(x,y,2) = p_cell * confidence_camera ;
    grid_evidential(x,y,4) = 1 - p_cell * confidence_camera ;
    aging_camera(x,y,1) = time;
end
end