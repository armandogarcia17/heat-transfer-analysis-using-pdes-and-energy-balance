classdef bh_sys_params_CLS
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = protected)
        Filename
        Sheetname
        my_tab
        %----------------------------------
        k_A  
        k_B    
        k_C  
        h_ROOF 
        h_CEIL 
        T_ROOF 
        T_CEIL
        %----------------------------------
        xLA
        xLB
        xLC
        yLA
        yLB
        yLC      
        %----------------------------------
        Nx_A
        Nx_B
        Nx_C
        Ny_A
        Ny_B
        Ny_C
    end
    
    properties
        Delta_X  
        Delta_Y 
    end
    
    
    methods
        function OBJ = bh_sys_params_CLS(Filename, Sheetname)
            arguments
               Filename  (1,1) string 
               Sheetname (1,1) string
            end
            
            OBJ.Filename  = Filename;
            OBJ.Sheetname = Sheetname;
            
            OBJ.my_tab = LOC_read_EXCEL_file(OBJ);
            %----------------------------------------
            OBJ.k_A    =  OBJ.my_tab{"ceil_k" ,  "Value"};
            OBJ.k_B    =  OBJ.my_tab{"joist_k",  "Value"};
            OBJ.k_C    =  OBJ.my_tab{"batt_k" ,  "Value"};
            OBJ.h_ROOF =  OBJ.my_tab{"roof_h",   "Value"};
            OBJ.h_CEIL =  OBJ.my_tab{"ceil_h",   "Value"};
            OBJ.T_ROOF =  OBJ.my_tab{"roof_T",   "Value"};
            OBJ.T_CEIL =  OBJ.my_tab{"ceil_T",   "Value"};
            
            OBJ.xLB    =  0.5 * OBJ.my_tab{"joist_width",  "Value"};
            OBJ.xLC    =  0.5 * OBJ.my_tab{"batt_width",  "Value"};
            OBJ.xLA    =  OBJ.xLB + OBJ.xLC;
            OBJ.yLB    =        OBJ.my_tab{"joist_height",  "Value"};
            OBJ.yLC    =        OBJ.my_tab{"batt_height",  "Value"};
            OBJ.yLA    =        OBJ.my_tab{"ceil_height",  "Value"};
            
            %OBJ.my_tab.Name = 
        end % bh_sys_params_CLS
        %------------------------------------------------------------------
        function obj = set_deltas(obj, dx, dy)
            obj.Delta_X = dx;
            obj.Delta_Y = dy;
            
            obj.Nx_A = round(obj.xLA / dx);
            obj.Nx_B = round(obj.xLB / dx);
            obj.Nx_C = round(obj.xLC / dx);
            
            obj.Ny_A = round(obj.yLA / dy);
            obj.Ny_B = round(obj.yLB / dy);
            obj.Ny_C = round(obj.yLC / dy);
            
            my_TOL = 1e-3;
            
            diff_val = abs(obj.xLA - obj.Nx_A * obj.Delta_X);
               assert(diff_val < my_TOL, "###_ERROR:  dx bad for xLA");
            diff_val = abs(obj.xLB - obj.Nx_B * obj.Delta_X);
               assert(diff_val < my_TOL, "###_ERROR:  dx bad for xLB");
            diff_val = abs(obj.xLC - obj.Nx_C * obj.Delta_X);
               assert(diff_val < my_TOL, "###_ERROR:  dx bad for xLC");
            diff_val = abs(obj.yLA - obj.Ny_A * obj.Delta_Y);
               assert(diff_val < my_TOL, "###_ERROR:  dy bad for yLA");
            diff_val = abs(obj.yLB - obj.Ny_B * obj.Delta_Y);
               assert(diff_val < my_TOL, "###_ERROR:  dy bad for yLB");
            diff_val = abs(obj.yLC - obj.Ny_C * obj.Delta_Y);
               assert(diff_val < my_TOL, "###_ERROR:  dy bad for yLC");
        end
        %------------------------------------------------------------------
    end % methods
end % classdef
%_#########################################################################
function my_tab = LOC_read_EXCEL_file(OBJ)

    opts = detectImportOptions(OBJ.Filename, "Sheet", OBJ.Sheetname);  
    
    opts = setvaropts(opts, ["Name", "Units", "Description", "Comments"], ...
                            'Type', 'string' );
    
    my_tab = readtable(OBJ.Filename, opts);
    
    % allow ROWNAMES to be usde as an index
    my_tab.Properties.RowNames = my_tab.Name;
end
