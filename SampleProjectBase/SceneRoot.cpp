#include "SceneRoot.h"
#include <stdio.h>
#include "CameraDCC.h"
#include "MoveLight.h"
#include "Model.h"
#include "Input.h"
#include "Geometory.h"

#include "SceneBlank.h"
#include "SceneAnimation.h"
#include "SceneShading.h"
#include "SceneLight.h"
#include "SceneBumpmap.h"

#include "DebugLog.h"
#include "ScenePBR.h"


#define STR(var) #var

//--- 定数定義
enum SceneKind
{
	SCENE_BUMPMAP,

	
	SCENE_BLANK,
	SCENE_LIGHT,
	//SCENE_SHADING,
	//SCENE_ANIMATION,
	SCENE_MAX
};

/// <summary>
/// シーン切り替え
/// デバッグ出力の実装がダサいがC++だとenumの名前を
/// 文字列として取得するのが手間なので今回はこのまま
/// </summary>
void SceneRoot::ChangeScene()
{
	switch (m_index)
	{
	default:
	case SCENE_LIGHT:AddSubScene<SceneLight>();
		DebugLog::Log("SceneName = SCENE_LIGHT");
		break;
	case SCENE_BUMPMAP:AddSubScene<ScenePBR>();
		DebugLog::Log("SceneName = SCENE_BUMPMAP");
		break;
	case SCENE_BLANK:AddSubScene<SceneBlank>();
		DebugLog::Log("SceneName = SCENE_BLANK");
		break;
	/*case SCENE_ANIMATION:AddSubScene<SceneAnimation>();
		DebugLog::Log("SceneName = SCENE_ANIMATION");
		break;*/
	/*case SCENE_SHADING:AddSubScene<SceneShading>();
		DebugLog::Log("SceneName = SCENE_SHADING");
		break;*/
	
	}
}


//--- 構造体
// @brief シーン情報保存
struct ViewSetting
{
	DirectX::XMFLOAT3 camPos;
	DirectX::XMFLOAT3 camLook;
	DirectX::XMFLOAT3 camUp;
	float lightRadXZ;
	float lightRadY;
	float lightH;
	float lightSV;
	int index;
};
const char* SettingFileName = "Assets/setting.dat";

void SceneRoot::Init()
{
	// 保存データの読み込み
	ViewSetting setting =
	{
		DirectX::XMFLOAT3(0.0f, 1.0f, -5.0f),
		DirectX::XMFLOAT3(0.0f, 1.0f, 0.0f),
		DirectX::XMFLOAT3(0.0f, 1.0f, 0.0f),
		0.0f, DirectX::XM_PIDIV4,
		0.0f, 1.0f,
		SCENE_BLANK
	};
	FILE* fp;
	fopen_s(&fp, SettingFileName, "rb");
	if (fp)
	{
		fread(&setting, sizeof(ViewSetting), 1, fp);
		fclose(fp);
	}

	// カメラの作成
	CameraBase* pCamera = CreateObj<CameraDCC>("Camera");
	pCamera->SetPos(setting.camPos);
	pCamera->SetLook(setting.camLook);
	pCamera->SetUp(setting.camUp);

	// ライトの作成
	MoveLight* pLight = CreateObj<MoveLight>("Light");
	pLight->SetRot(setting.lightRadXZ, setting.lightRadY);
	pLight->SetHSV(setting.lightH, setting.lightSV);
	pLight->UpdateParam();

	// モデルの読み込み
	CreateObj<Model>("Model");
	GetObj<Model>("Model")->Load("Assets/Model/spot/spot.fbx", 1.0f, true);
	
	// アニメーション用モデル読み込み
	Model* pAnimModel = CreateObj<Model>("Akai");
	if (pAnimModel->Load("Assets/Model/Akai/Akai.fbx", 0.01f, true))
	{
		pAnimModel->LoadAnimation("Assets/Model/Akai/Akai_Run.fbx", "Run", true);
		pAnimModel->LoadAnimation("Assets/Model/Akai/Akai_Idle.fbx", "Idle", true);
		pAnimModel->LoadAnimation("Assets/Model/Akai/Akai_Walk.fbx", "Walk", true);
	}
	Model* pPlane = CreateObj<Model>("ModelPlane");
	pPlane->Load("Assets/Model/plane/plane.fbx");

	Model* pField = CreateObj<Model>("FieldModel");
	pField->Load("Assets/Model/field/field.fbx", 1.0f, false, true);

	// シーンの作成
	m_index = setting.index;
	ChangeScene();
}

void SceneRoot::Uninit()
{
	CameraBase* pCamera = GetObj<CameraBase>("Camera");
	MoveLight* pLight = GetObj<MoveLight>("Light");
	ViewSetting setting =
	{
		pCamera->GetPos(),
		pCamera->GetLook(),
		pCamera->GetUp(),
		pLight->GetRotXZ(), pLight->GetRotY(),
		pLight->GetH(), pLight->GetSV(),
		m_index
	};
	FILE* fp;
	fopen_s(&fp, SettingFileName, "wb");
	if (fp)
	{
		fwrite(&setting, sizeof(ViewSetting), 1, fp);
		fclose(fp);
	}
}

void SceneRoot::Update(float tick)
{
	CameraBase* pCamera = GetObj<CameraBase>("Camera");
	LightBase* pLight = GetObj<LightBase>("Light");
	if (!IsKeyPress(VK_SHIFT))
	{
		pCamera->Update();
		pLight->Update();
		return;
	}

	// SHIFTキーが押されてれば、シーンの切り替え処理
	int idx = m_index;
	if (IsKeyTrigger(VK_LEFT)) --idx;
	if (IsKeyTrigger(VK_RIGHT)) ++idx;
	if (idx < 0) idx = SCENE_MAX - 1;
	if (idx >= SCENE_MAX) idx = 0;

	if (idx != m_index)
	{
		m_index = idx;
		RemoveSubScene();
		ChangeScene();
	}

	// カメラ初期化
	if (IsKeyTrigger('R'))
	{
		pCamera->SetPos(DirectX::XMFLOAT3(0.0f, 1.0f, -5.0f));
		pCamera->SetLook(DirectX::XMFLOAT3(0.0f, 1.0f, 0.0f));
		pCamera->SetUp(DirectX::XMFLOAT3(0.0f, 1.0f, 0.0f));
	}
}
void SceneRoot::Draw()
{
	CameraBase* pCamera = GetObj<CameraBase>("Camera");
	LightBase* pLight = GetObj<LightBase>("Light");

	DirectX::XMFLOAT4X4 fmat;
	DirectX::XMStoreFloat4x4(&fmat, DirectX::XMMatrixIdentity());
	Geometory::SetWorld(fmat);
	Geometory::SetView(pCamera->GetView());
	Geometory::SetProjection(pCamera->GetProj());

	// 網掛け描画
	const int GridSize = 10;
	Geometory::SetColor(DirectX::XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f));
	for (int i = 1; i <= GridSize; ++i)
	{
		float g = (float)i;
		Geometory::AddLine(DirectX::XMFLOAT3(g, 0.0f, -GridSize), DirectX::XMFLOAT3(g, 0.0f, GridSize));
		Geometory::AddLine(DirectX::XMFLOAT3(-g, 0.0f, -GridSize), DirectX::XMFLOAT3(-g, 0.0f, GridSize));
		Geometory::AddLine(DirectX::XMFLOAT3(-GridSize, 0.0f, g), DirectX::XMFLOAT3(GridSize, 0.0f, g));
		Geometory::AddLine(DirectX::XMFLOAT3(-GridSize, 0.0f, -g), DirectX::XMFLOAT3(GridSize, 0.0f, -g));
	}
	// 軸描画
	Geometory::SetColor(DirectX::XMFLOAT4(1.0f, 0.0f, 0.0f, 1.0f));
	Geometory::AddLine(DirectX::XMFLOAT3(-GridSize, 0.0f, 0.0f), DirectX::XMFLOAT3(GridSize, 0.0f, 0.0f));
	Geometory::SetColor(DirectX::XMFLOAT4(0.0f, 1.0f, 0.0f, 1.0f));
	Geometory::AddLine(DirectX::XMFLOAT3(0.0f, -GridSize, 0.0f), DirectX::XMFLOAT3(0.0f, GridSize, 0.0f));
	Geometory::SetColor(DirectX::XMFLOAT4(0.0f, 0.0f, 1.0f, 1.0f));
	Geometory::AddLine(DirectX::XMFLOAT3(0.0f, 0.0f, -GridSize), DirectX::XMFLOAT3(0.0f, 0.0f, GridSize));

	Geometory::DrawLines();

	// オブジェクト描画
	pCamera->Draw();
	pLight->Draw();
}
