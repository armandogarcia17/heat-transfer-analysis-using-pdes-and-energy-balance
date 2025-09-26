classdef bh_fd_mesh_CLS
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = protected )
        tab
        T_list string
        A_sys 
        b_sys 
        x_sys 
    end
    
    methods
        function obj = bh_fd_mesh_CLS(block_A, block_B, block_C)
            arguments
                block_A (1,1) bh_block_CLS
                block_B (1,1) bh_block_CLS
                block_C (1,1) bh_block_CLS
            end
            
            [obj.tab, obj.T_list] = LOC_join(block_A, block_B, block_C);

        end
        %------------------------------------------------------------------
        function  plot(obj)
            LOC_plot(obj.tab)
        end
        %------------------------------------------------------------------
        function obj = assemble_sys_A_b(obj, obj_stencil)
            arguments
               obj         (1,1)
               obj_stencil (1,1) bh_fd_stencil_CLS
            end
          NUM_NODES = height(obj.tab);
          
          A_sys = sparse(NUM_NODES, NUM_NODES);
          b_sys = sparse(NUM_NODES, 1);
          
          for kk=1:NUM_NODES  
            
              m  = obj.tab.i_global(kk);
              n  = obj.tab.j_global(kk);
              node_type_str = obj.tab.node_type_fd(kk);
              
              % get the STENCIl for this node type
              [A, b, x_str] = obj_stencil.retrieve_Abx(node_type_str, m, n);
              
              assert(length(x_str) > 0, "###_ERROR:  bad !")
              
              %---------------------------
              % REALLY SLOW HERE
              % [~,ia,ib] = intersect(obj.T_list, x_str);               
              % A_sys(kk, ia) = A(1,ib);
              % b_sys(kk)     = b;
              %----------------------------
              ia = zeros(size(x_str));
              for ii=1:length(x_str)
                 ia(ii) = find(obj.T_list == x_str(ii) );
              end % for ii
              
              A_sys(kk, ia) = A(1,:);
              b_sys(kk)     = b;
              
              if(0==mod(kk,1000))
                  fprintf('\n ... completed kk=%5d',kk);
              end
              
          end % for kk=1:NUM_NODES
          
          % take care of the internal results fields
          obj.A_sys = A_sys;
          obj.b_sys = b_sys;
          
        end
        %------------------------------------------------------------------
        function obj = solve(obj)
            % x = A \ b
            x_sys     =  obj.A_sys \ obj.b_sys   ;
            
            obj.x_sys = x_sys;
            
            mn_mat  = [ obj.tab.i_global,  obj.tab.j_global];          
        end
        %------------------------------------------------------------------
        function [T_col, mn_mat] = results_retrieve(obj)
           T_col  = full( obj.x_sys );
           mn_mat = [ obj.tab.i_global, obj.tab.j_global ];           
        end
        %------------------------------------------------------------------
        function results_plot(obj, plot_style)
          arguments
             obj
             plot_style (1,1) string {mustBeMember(plot_style,["scatter", "surf"])}
          end
          
          m_col = obj.tab.i_global; 
          n_col = obj.tab.j_global; 
          T_col = full( obj.x_sys );

          switch(plot_style)
              case "scatter"                  
                      figure;
                      scatter3(m_col, n_col, T_col, [], T_col)
                         xlabel('X'); ylabel('Y'); 
                         grid('On')
                         colormap(jet(200))            
                         colorbar;
                         view(2)
              case "surf"
                   % uses Convex hull ... so don't like this
%                    F = scatteredInterpolant(m_col, n_col, T_col, ...
%                                   'linear', 'none');
%                   
%                    m_list = linspace(min(m_col), max(m_col), 200);
%                    n_list = linspace(min(n_col), max(n_col), 200);
%                    [M,N]  = meshgrid(m_list, n_list);
%                    T      = F(M,N);
%                    
%                    figure;
%                    surf(M,N,T,'EdgeColor','none');
%                          xlabel('X'); ylabel('Y'); 
%                          grid('On')
%                          colormap(jet(200))            
%                          colorbar;
          end % switch
        end
        %------------------------------------------------------------------
        %------------------------------------------------------------------
    end
end
%_#########################################################################
% LOCAL SUBFUNCTIONS
%_#########################################################################
function [res_tab, T_str_list] = LOC_join(block_A, block_B, block_C)

    A_in  = get_subtable(block_A, "NODES_INTERNAL");
    A_SW  = get_subtable(block_A, "NODES_SW_CORNER");
    A_W   = get_subtable(block_A, "NODES_WEST_FACE_EXCLUDING_CORNERS");
    A_S   = get_subtable(block_A, "NODES_SOUTH_FACE_EXCLUDING_CORNERS");
    A_SE  = get_subtable(block_A, "NODES_SE_CORNER");
    A_E   = get_subtable(block_A, "NODES_EAST_FACE_EXCLUDING_CORNERS");
    
    A_in{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_INTERNAL);
    A_SW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_SW);
    A_W{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_W);
    A_S{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_S);
    A_SE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_SE);
    A_E{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_A_E);
    
    A_tab     = [A_in; A_SW; A_W; A_S; A_SE; A_E];  
    %---------------------------------------------        
    B_in = get_subtable(block_B, "NODES_INTERNAL"); 
    B_NW = get_subtable(block_B, "NODES_NW_CORNER");     
    B_N  = get_subtable(block_B, "NODES_NORTH_FACE_EXCLUDING_CORNERS");        
    B_NE = get_subtable(block_B, "NODES_NE_CORNER");         
    B_E  = get_subtable(block_B, "NODES_EAST_FACE_EXCLUDING_CORNERS");        
    B_SE = get_subtable(block_B, "NODES_SE_CORNER");        
    B_S  = get_subtable(block_B, "NODES_SOUTH_FACE_EXCLUDING_CORNERS");        
    B_SW = get_subtable(block_B, "NODES_SW_CORNER");       
    B_W  = get_subtable(block_B, "NODES_WEST_FACE_EXCLUDING_CORNERS");       
         
    B_in{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_INTERNAL);  
    B_NW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_NW);      
    B_N{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_N);          
    B_NE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_NE);          
    B_E{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_E);        
    B_SE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_SE);       
    B_S{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_S);          
    B_SW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_SW);        
    B_W{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_B_W);         
       
    B_tab = [B_in; B_NW; B_N; B_NE; B_E; B_SE; B_S; B_SW; B_W];
    %---------------------------------------------        
    C_in = get_subtable(block_C, "NODES_INTERNAL"); 
    C_NW = get_subtable(block_C, "NODES_NW_CORNER");     
    C_N  = get_subtable(block_C, "NODES_NORTH_FACE_EXCLUDING_CORNERS");        
    C_NE = get_subtable(block_C, "NODES_NE_CORNER");         
    C_E  = get_subtable(block_C, "NODES_EAST_FACE_EXCLUDING_CORNERS");        
    C_SE = get_subtable(block_C, "NODES_SE_CORNER");        
    C_S  = get_subtable(block_C, "NODES_SOUTH_FACE_EXCLUDING_CORNERS");        
    C_W  = get_subtable(block_C, "NODES_WEST_FACE_EXCLUDING_CORNERS");       
         
    % now delete nodes that join the B-block boundary
    tf_ind =  (C_W.i_local) == 0 &  (C_W.j_local <= block_B.Ny);
    C_W(tf_ind,:) = [];
        
    C_in{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_INTERNAL);  
    C_NW{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_NW);      
    C_N{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_N);          
    C_NE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_NE);          
    C_E{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_E);        
    C_SE{:, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_SE);       
    C_S{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_S);          
    C_W{ :, "node_type_fd"} = string(bh_fd_node_type_ENUM.G_BLK_C_W);         
       
    C_tab = [C_in; C_NW; C_N; C_NE; C_E; C_SE; C_S; C_W];
    %---------------------------------------------        
    res_tab =  [A_tab;
                B_tab;
                C_tab ];
            
    res_tab.NODE_NAME = "NODE_" + res_tab.i_global + "_" + res_tab.j_global;
    
    % allow the table ROW index to be the NODE_ID
    res_tab.Properties.RowNames = res_tab.NODE_NAME;
    %----------------------------------------------
    T_str_list = "T_" + res_tab.i_global + "_" + res_tab.j_global;
end
%--------------------------------------------------------------------------
function LOC_plot(tab)

    unq_node_types = unique(tab.node_type_fd);

    N              = length(unq_node_types);
    RGB_mat        = jet(N);

    figure
    hax = axes;
    hold(hax,"on");
    for kk=1:N
        THE_node_type = unq_node_types(kk);

        tf_ind  = tab.node_type_fd == THE_node_type;

        sub_tab = tab(tf_ind,:);

        x_list  = sub_tab.i_global;
        y_list  = sub_tab.j_global;

        if( contains(THE_node_type, "NE") | contains(THE_node_type, "NW") | ...
            contains(THE_node_type, "SE") | contains(THE_node_type, "SW") )
            tmp_mkr_size = 30;
        else
            tmp_mkr_size = 10;
        end

        plot(hax, x_list, y_list, '.', "Color", RGB_mat(kk,:), "MarkerSize",tmp_mkr_size);
    end

    grid(hax,'on');
end
%--------------------------------------------------------------------------

