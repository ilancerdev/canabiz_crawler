class SourcesController < ApplicationController
    
    before_action :set_source, only: [:edit, :update, :destroy, :show]
    before_action :require_admin, except: [:show]

    #--------ADMIN PAGE-------------------------
    def admin
        @sources = Source.all.order(sort_column + " " + sort_direction)
    
        #for csv downloader
        respond_to do |format|
            format.html
            format.csv {render text: @sources.to_csv }
        end
    end
    
    #method is used for csv file upload
    def import
        Source.import(params[:file])
        flash[:success] = 'Sources were successfully imported'
        redirect_to source_admin_path 
    end
    
    def search
        @q = "%#{params[:query]}%"
        @sources = Source.where("name LIKE ? or source_type LIKE ?", @q, @q).order(sort_column + " " + 
                                    sort_direction).paginate(page: params[:page], per_page: 50)
        render 'admin'
    end
    #--------ADMIN PAGE-------------------------
    
    #-------------------------------------------
    def new
      @source = Source.new
    end
    def create
        @source = Source.new(source_params)
        if @source.save
            flash[:success] = 'Source was successfully created'
            redirect_to source_admin_path
        else 
            render 'new'
        end
    end
    
    #-------------------------------------------
    
    def show
        #probably show the products or the articles depending on the type
    end

    #-------------------------------------------
    
    def edit
    end   
    def update
        if @source.update(source_params)
            flash[:success] = 'Source was successfully updated'
            redirect_to source_admin_path
        else 
            render 'edit'
        end
    end 
    
    #-------------------------------------------
   
    def destroy
        @source.destroy
        flash[:success] = 'Source was successfully deleted'
        redirect_to source_admin_path
    end
   
    def destroy_multiple
        Source.destroy(params[:sources])
        flash[:success] = 'Sources were successfully deleted'
        redirect_to source_admin_path        
    end
    
    #-------------------------------------------

  
    private
    
        def require_admin
            if !logged_in? || (logged_in? and !current_user.admin?)
                flash[:danger] = 'Only administrators can visit that page'
                redirect_to root_path
            end
        end
        
        def set_source
          @source = Source.find(params[:id])
        end
        
        def source_params
          params.require(:source).permit(:name, :source_type, :article_logo, :sidebar_logo, :url)
        end  
        
        def sort_column
            params[:sort] || "name"
        end
        def sort_direction
            params[:direction] || 'desc'
        end
end