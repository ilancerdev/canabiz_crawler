class ArticlesController < ApplicationController
    before_action :set_article, only: [:edit, :update, :destroy, :show, :tweet, :send_tweet]
    before_action :require_admin, only: [:edit, :update, :destroy, :admin, :digest, :tweet]

    #--------ADMIN PAGE-------------------------
    def admin
        @articles = Article.order(sort_column + " " + sort_direction).paginate(page: params[:page], per_page: 20)
    
        #for csv downloader
        respond_to do |format|
            format.html
            format.csv {render text: @articles.to_csv }
        end
    end
    
    #method is used for csv file upload
    def import
        Article.import(params[:file])
        flash[:success] = 'Articles were successfully imported'
        redirect_to article_admin_path 
    end
    
    def search
        @q = "%#{params[:query]}%"
        @articles = Article.where("title LIKE ? or abstract LIKE ?", @q, @q).order(sort_column + " " + 
                                    sort_direction).paginate(page: params[:page], per_page: 50)
        render 'admin'
    end
    
    def tweet
        #not on admin page but admin functionality
    end
    
    def send_tweet
        
       	require 'rubygems'
		require 'oauth'
		require 'json'
		
		if params[:tweet_body].present?
		    
            client = Twitter::REST::Client.new do |config|
                config.consumer_key    = "PeKIPXsMPl80fKm6SipbqrRVL"
                config.consumer_secret = "EzcwBZ1lBd8RlnhbuDyxt3URqPyhrBpDq00Z6n4btsnaPF7VpO"
                config.access_token    = "418377285-HfXt8G0KxvBhNXQJRnnysTvt7yGAM0jWyfaIKSIU"
                config.access_token_secret = "3QF4wvh1ESmSuKqWztD8LibyVJHhYNMcc93YlTWdrPqez"
            end
            
            if @article.image.present?
                data = open(@article.image)
                client.update_with_media(params[:tweet_body], File.new(data))
            else 
                client.update(params[:tweet_body])
            end
            
            flash[:success] = 'Tweet Sent'
            redirect_to root_path
            
        else
            flash[:danger] = 'No Tweet Sent'
            redirect_to root_path
        end
    end
    
    def digest
        #not on admin page but admin functionality
    end
    
    #--------ADMIN PAGE-------------------------
    
    def index
        @top_articles = Article.where('image IS NOT NULL').limit(4)
        @categories = Category.order("RANDOM()").limit(4) #randomize the categories that are returned
    end

    #-----------------------------------
    def new
      @article = Article.new
    end
    def create
      @article = Article.new(article_params)
      if @article.save
         flash[:success] = 'Article was successfully created'
         redirect_to article_admin_path
      else 
         render 'new'
      end
    end 
    #-----------------------------------
    
    def show
        #related articles
        if @article.categories.present?
            @related_articles = Article.all.order("RANDOM()").limit(3) 
        elsif @article.states.present?
            @related_articles = Article.all.order("RANDOM()").limit(3)  
        else
            @related_articles = Article.all.order("RANDOM()").limit(3)
        end
        
        #same source articles
        @same_source_articles = Article.where(source_id: @article.source).limit(3)
        
        #add view to article for sorting
        @article.increment(:num_views, by = 1)
        @article.save
        
        #add userView record
        if current_user
            #the table isn't created yet
        end
    end
    
    #-----------------------------------
    def edit
    end   
    def update
        if @article.update(article_params)
            flash[:success] = 'Article was successfully updated'
            redirect_to article_admin_path
        else 
            render 'edit'
        end
    end 
    #-----------------------------------
   
    def destroy
        @article.destroy
        flash[:success] = 'Article was successfully deleted'
        redirect_to article_admin_path
    end 
   
    def destroy_multiple
      Article.destroy(params[:articles])
      flash[:success] = 'Articles were successfully deleted'
      redirect_to article_admin_path        
    end   
    
    private 
        def require_admin
            if !logged_in? || (logged_in? and !current_user.admin?)
                flash[:danger] = 'Only administrators can visit that page'
                redirect_to root_path
            end
        end
        
        def set_article
            @article = Article.find(params[:id])
            if @article.blank?
                flash[:danger] = 'The page you are looking for does not exist'
                redirect_to root_path 
            end
        end
        def article_params
            params.require(:article).permit(:title, :abstract, :body, :date, :image, :remote_image_url, :remote_file_url, :source_id, :include_in_digest, state_ids: [], category_ids: [])
        end
      
        def sort_column
            params[:sort] || "date"
        end
        def sort_direction
            params[:direction] || 'desc'
        end
          
end