class ToDosController < ApplicationController
  def index
    @todos = current_user.to_dos.sorted
  end

  def edit
    @todo = ToDo.find(params[:id])
    @todo_count = current_user.to_dos.count
  end

  def new
    @todo = ToDo.new
    @todo_count = current_user.to_dos.count + 1
  end

  def create
    @todo = ToDo.new(todo_params)
    @todo.creator_id = current_user.id

    if @todo.save
      redirect_to(:action => 'index')
    else
      @todo = ToDo.new
      @todo_count = current_user.to_dos.count + 1
      render('new')
    end
  end

  def update
    @todo = ToDo.find(params[:id])

    if @todo.update_attributes(todo_params)
      redirect_to(:action => 'index')
    else
      @todo = ToDo.new
      @todo_count = current_user.to_dos.count + 1
      render('new')
    end
  end

  def destroy
    @todo = ToDo.find(params[:id])
    @todo.destroy
    flash[:notice] = "To-do '#{@todo.title}' deleted successfully"
    redirect_to(to_dos_index_path)
  end

  private

  def todo_params
    params.require(:to_do).permit(:title,:description,:duration,:position,:recurrence)
  end

end
