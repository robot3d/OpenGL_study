#shader vertex
#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normal;
layout(location = 2) in vec2 texture_coords;

out vec3 o_Normal;
out vec3 o_FragPos;
out vec2 o_TextureCoords;

uniform mat4 u_Model;
uniform mat4 u_View;
uniform mat4 u_Proj;

void main()
{
    gl_Position = u_Proj * u_View * u_Model * position;
    o_Normal = mat3(transpose(inverse(u_Model))) * normal.xyz;
    o_FragPos = vec3(u_Model * position);
    o_TextureCoords = texture_coords;
}

#shader fragment
#version 330 core

struct Material {
    sampler2D   diffuse;
    sampler2D   specular;
    float       shininess;
};

struct Light {
    // 类型
    // 0 平行光
    // 1 点光源
    // 2 聚光灯
    int     type;      

    vec3    direction;
    vec3    position;

    // --- 基本参数 --- //
    vec3    ambient;    // 环境光
    vec3    diffuse;    // 漫反射光
    vec3    specular;   // 镜面光

    // --- 点光源参数 --- 参考 https://learnopengl-cn.github.io/02%20Lighting/05%20Light%20casters/ //
    float   constant;   // 常量
    float   linear;     // 一次项
    float   quadratic;  // 二次项

    // --- 聚光灯参数 --- //
    float   cut_off;
    float   outer_cut_off;
};

layout(location = 0) out vec4 color;

uniform vec3 u_ViewPos;
uniform Material u_Material;
uniform Light u_Light;
uniform float u_DistanceRate;

in vec3 o_Normal;
in vec3 o_FragPos;
in vec2 o_TextureCoords;

void main()
{
    // normal && light dir
    vec3 norm = normalize(o_Normal);
    vec3 light_dir;
    float attenuation = 1.0;

    // w 分量为0，表示方向向量，w 分量为1，表示位置向量
    if (u_Light.type == 0)
    {
        light_dir = normalize(-u_Light.direction);
    }
    else
    {
        light_dir = normalize(u_Light.position - o_FragPos);

        if (u_Light.type == 1)
        {
            float distance = length(vec3(u_Light.direction) - o_FragPos) / u_DistanceRate;
            attenuation = 1.0 /
                (u_Light.constant + u_Light.linear * distance + u_Light.quadratic * (distance * distance));
        }
    }

    // ambient
    vec3 ambient = u_Light.ambient * vec3(texture(u_Material.diffuse, o_TextureCoords));

    // diffuse
    float diff   = max(dot(norm, light_dir), 0.0);
    vec3 diffuse = u_Light.diffuse * (diff * vec3(texture(u_Material.diffuse, o_TextureCoords)));

    // specular
    vec3 view_dir    = normalize(u_ViewPos - o_FragPos);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec       = pow(max(dot(norm, halfway_dir), 0.0), u_Material.shininess);
    vec3 specular    = u_Light.specular * (spec * vec3(texture(u_Material.specular, o_TextureCoords)));

    if (u_Light.type == 2)
    {
        float theta     = dot(light_dir, normalize(-u_Light.direction));
        float epsilon   = u_Light.cut_off - u_Light.outer_cut_off;
        float intensity = clamp((theta - u_Light.outer_cut_off) / epsilon, 0.0f, 1.0f);

        diffuse  *= intensity;
        specular *= intensity;
    }

    // result
    vec3 result = (ambient + diffuse + specular) * attenuation;
    color = vec4(result, 1.0);
}
