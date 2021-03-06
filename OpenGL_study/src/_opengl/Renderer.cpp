#include "Renderer.h"

Renderer::Renderer()
    : clear_color_(glm::vec4(0.0f))
{
}

Renderer::~Renderer() = default;

void Renderer::clear() const
{
    GLCall(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT));
}

void Renderer::draw(const VertexArray& va, const Shader& shader) const
{
    shader.bind();
    va.bind();

    GLCall(glDrawElements(GL_TRIANGLES, 
                          va.get_index_buffer()->get_count(), 
                          GL_UNSIGNED_INT, nullptr));
    shader.unbind();
    va.unbind();
}

void Renderer::draw(Mesh& mesh, Shader& shader) const
{
    mesh.draw(*this, shader);
}

void Renderer::draw(Model& model, Shader& shader) const
{
    model.draw(*this, shader);
}

void Renderer::set_clear_color(const glm::vec4 color)
{
    if (color != clear_color_)
    {
        clear_color_ = color;
        GLCall(glClearColor(color.x, color.y, color.z, color.w));
    }
}
