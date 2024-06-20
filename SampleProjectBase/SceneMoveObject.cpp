#include "math.h"
#include "SceneMoveObject.h"
#include "Geometory.h"
#include "DebugLog.h"

using namespace DirectX;
using namespace DirectX::SimpleMath;

void SceneMoveObject::Init()
{

}
void SceneMoveObject::Uninit()
{

}
void SceneMoveObject::Update(float tick)
{

}
void SceneMoveObject::Draw()
{
	DirectX::XMFLOAT4X4 mat;
	//ãÖÇÃç¿ïWçsóÒçÏê¨
	DirectX::XMStoreFloat4x4(&mat, DirectX::XMMatrixTranspose(
		DirectX::XMMatrixScaling(1.f, 1.f, 1.f) *
		DirectX::XMMatrixTranslation(0.f, 0.f, 0.f)
	));

	Geometory::SetWorld(mat);
	Geometory::DrawSphere();
}
