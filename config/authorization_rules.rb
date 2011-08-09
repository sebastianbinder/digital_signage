authorization do

  role :admin do
  
    has_omnipotence
    
  end
  
  role :manager do
    
    has_permission_on :dashboard do
      to :read
    end
    
    has_permission_on :announcements do
      to :read
      if_attribute :show? => is {true}
    end
    
    has_permission_on :users do
      to :show
      if_attribute :id => is {user.id}
    end
   
    has_permission_on :signs, :to => [:read, :update] do
      if_permitted_to :show, :department
    end
    
    has_permission_on :slides, :to => [:read, :create]
    has_permission_on :slides, :to => :update do
      if_permitted_to :show, :department
    end
    
    has_permission_on :slots, :to => [:administrate, :sort] do
      if_permitted_to :update, :sign
    end
    
    has_permission_on :departments, :to => :show do
      if_attribute :users => contains {user}
    end
    
    includes :guest
    
  end
  
  role :guest do
  
    has_permission_on :pages do
      to :feedback
    end
  
    has_permission_on :documents do
      to :read
    end
    
    has_permission_on :info do
      to :appinfo
    end
    
    has_permission_on :signs do
      to :show, :check_in
    end
    
  end
  
end

privileges do
  privilege :create, :includes => :new
  privilege :read, :includes => [:index, :show]
  privilege :update, :includes => :edit
  privilege :delete, :includes => :destroy
  privilege :administrate, :includes => [:create, :read, :update, :delete, :auto_update]
end
