import std/[strutils, strformat]
import ./shared

type

  EventKind* = enum
    Workspace = "workspace"
    WorkspaceV2 = "workspacev2"
    FocusedMon = "focusedmon"
    ActiveWindow = "activewindow"
    ActiveWindowV2 = "activewindowv2"
    Fullscreen = "fullscreen"
    MonitorRemoved = "monitorremoved"
    MonitorAdded = "monitoradded"
    MonitorAddedV2 = "monitoraddedv2"
    CreateWorkspace = "createworkspace"
    CreateWorkspaceV2 = "createworkspacev2"
    DestroyWorkspace = "destroyworkspace"
    DestroyWorkspaceV2 = "destroyworkspacev2"
    MoveWorkspace = "moveworkspace"
    MoveWorkspaceV2 = "moveworkspacev2"
    RenameWorkspace = "renameworkspace"
    ActiveSpecial = "activespecial"
    ActiveLayout = "activelayout"
    OpenWindow = "openwindow"
    CloseWindow = "closewindow"
    MoveWindow = "movewindow"
    MoveWindowV2 = "movewindowv2"
    OpenLayer = "openlayer"
    CloseLayer = "closelayer"
    Submap = "submap"
    ChangeFloatingMode = "changefloatingmode"
    Urgent = "urgent"
    Minimize = "minimize"
    Screencast = "screencast"
    WindowTitle = "windowtitle"
    WindowTitleV2 = "windowtitlev2"
    ToggleGroup = "togglegroup"
    MoveIntoGroup = "moveintogroup"
    MoveOutOfGroup = "moveoutofgroup"
    IgnoreGroupLock = "ignoregrouplock"
    LockGroups = "lockgroups"
    ConfigReloaded = "configreloaded"
    Pin = "pin"

  # All combinations of parameters the events have. These fields could be moved into the Event object
  # if case objects supported multiple cases with shared fields.
  WorkspaceData = tuple[workspaceName: string]
  WorkspaceDataV2 = tuple[workspaceID: int, workspaceName: string]
  MoveWorkspaceDataV2 = tuple[workspaceID: int; monName, workspaceName: string]
  FocusedMonData = tuple[monName: string, workspaceName: string]
  ActiveWindowData = tuple[windowClass: string, windowTitle: string]
  WindowAddressData = tuple[windowAddress: Address]
  MonitorData = tuple[monitorName: string]
  MonitorDataV2 = tuple[monitorID: int, monitorName: string, monitorDescription: string]
  StateData = tuple[state: bool]
  LayoutData = tuple[keyboardName: string, layoutName: string]
  OpenWindowData = tuple[windowAddress: Address; workspaceName, windowClass, windowTitle: string]
  MoveWindowDataV2 = tuple[windowAddress: Address, workspaceId: int, workspaceName: string]
  MoveWindowData = tuple[windowAddress: Address, workspaceName: string]
  LayerData = tuple[namespace: string]
  SubmapData = tuple[submapName: string]
  WindowStateData = tuple[windowAddress: Address, state: bool]
  WindowTitleData = tuple[windowAddress: Address, title: string]
  ScreencastData = tuple[state: bool, owner: int]
  ToggleGroupData = tuple[state: bool, windowAddresses: seq[Address]]

  Event = object
    case kind*: EventKind
    of Workspace, CreateWorkspace, DestroyWorkspace, MoveWorkspace, ActiveSpecial:
      wsData*: WorkspaceData
    of WorkspaceV2, CreateWorkspaceV2, DestroyWorkspaceV2, RenameWorkspace:
      wsDataV2*: WorkspaceDataV2
    of FocusedMon:
      focusData*: FocusedMonData
    of ActiveWindow:
      winData*: ActiveWindowData
    of ActiveWindowV2, CloseWindow, WindowTitle, Urgent, MoveIntoGroup, MoveOutOfGroup:
      winDataV2*: WindowAddressData
    of Fullscreen, IgnoreGroupLock, LockGroups:
      stateData*: StateData
    of MonitorRemoved, MonitorAdded:
      monitorData*: MonitorData
    of MonitorAddedV2:
      monitorDataV2*: MonitorDataV2
    of MoveWorkspaceV2:
      moveWsData*: MoveWorkspaceDataV2
    of ActiveLayout:
      layoutData*: LayoutData
    of OpenWindow:
      openWinData*: OpenWindowData
    of MoveWindow:
      moveWinData*: MoveWindowData
    of MoveWindowV2:
      moveWinDataV2*: MoveWindowDataV2
    of OpenLayer, CloseLayer:
      layerData*: LayerData
    of Submap:
      submapData*: SubmapData
    of ChangeFloatingMode, Minimize, Pin:
      changeFloatingData*: WindowStateData
    of Screencast:
      screencastData*: ScreencastData
    of WindowTitleV2:
      winTitleDataV2*: WindowTitleData
    of ToggleGroup:
      toggleGroupData*: ToggleGroupData
    of ConfigReloaded:
      discard

proc getPendingEvents*(): seq[Event] =
  let eventData = getPendingEventData()
  for event in eventData:
    var parts = event.split(">>")
    parts[1].stripLineEnd()
    for kind in EventKind:
      if parts[0] == $kind: 
        # This parsing should be easy to do with macros, because the data tuple fields are
        # in the same order as they are in the event text.
        let args = parts[1].split(',')
        var event = Event(kind: kind)
        case kind
        of Workspace, CreateWorkspace, DestroyWorkspace, MoveWorkspace, ActiveSpecial:
          event.wsData.workspaceName = parts[1]
        of WorkspaceV2, CreateWorkspaceV2, DestroyWorkspaceV2, RenameWorkspace:
          event.wsDataV2 = (parseInt(args[0]), args[1])
        of FocusedMon:
          event.focusData = (args[0], args[1])
        of ActiveWindow:
          event.winData = (args[0], args[1])
        of ActiveWindowV2, CloseWindow, WindowTitle, Urgent, MoveIntoGroup, MoveOutOfGroup:
          event.winDataV2.windowAddress = args[0]
        of Fullscreen, IgnoreGroupLock, LockGroups:
          event.stateData.state = parseBool(args[0])
        of MonitorRemoved, MonitorAdded:
          event.monitorData.monitorName = args[0]
        of MonitorAddedV2:
          event.monitorDataV2 = (parseInt(args[0]), args[1], args[2])
        of MoveWorkspaceV2:
          event.moveWsData = (parseInt(args[0]), args[1], args[2])
        of ActiveLayout:
          event.layoutData = (args[0], args[1])
        of OpenWindow:
          event.openWinData = (args[0], args[1], args[2], args[3])
        of MoveWindow:
          event.moveWinData = (args[0], args[1])
        of MoveWindowV2:
          event.moveWinDataV2 = (args[0], parseInt(args[1]), args[2])
        of OpenLayer, CloseLayer:
          event.layerData.namespace = args[0]
        of Submap:
          event.submapData.submapName = args[0]
        of ChangeFloatingMode, Minimize, Pin:
          event.changeFloatingData = (args[0], parseBool(args[1]))
        of Screencast:
          event.screencastData = (parseBool(args[0]), parseInt(args[1]))
        of WindowTitleV2:
          event.winTitleDataV2 = (args[0], args[1])
        of ToggleGroup:
          let winAddresses = args[1..^1]
          event.toggleGroupData = (parseBool(args[0]), winAddresses)
        of ConfigReloaded:
          discard
        else:
          echo fmt"WARNING: Parsing not supported for event type {kind}. Got Data {parts[1]}."
          result.add Event(kind: kind)
        result.add event
